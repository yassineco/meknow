// =====================================================
// ROUTES GESTION DES PRODUITS
// =====================================================

// Ajouter ceci au backend-v2.js après la section d'authentification

// =====================================================
// API PRODUITS - LECTURE
// =====================================================

// Lister tous les produits (public - pour le frontend)
app.get('/api/products', async (req, res) => {
  try {
    const { limit = 50, offset = 0, status = 'published' } = req.query;

    const result = await pool.query(`
      SELECT 
        p.*,
        JSON_AGG(
          JSON_BUILD_OBJECT(
            'id', pv.id,
            'title', pv.title,
            'sku', pv.sku,
            'price', pv.price,
            'inventory_quantity', pv.inventory_quantity,
            'option1', pv.option1
          )
        ) as variants
      FROM products p
      LEFT JOIN product_variants pv ON p.id = pv.product_id
      WHERE p.status = $1
      GROUP BY p.id
      ORDER BY p.created_at DESC
      LIMIT $2 OFFSET $3
    `, [status, limit, offset]);

    res.json({
      success: true,
      products: result.rows,
      count: result.rows.length
    });

  } catch (err) {
    console.error('❌ Erreur récupération produits:', err);
    res.status(500).json({
      success: false,
      error: 'Erreur lors de la récupération des produits'
    });
  }
});

// Récupérer un produit par ID ou handle
app.get('/api/products/:identifier', async (req, res) => {
  try {
    const { identifier } = req.params;
    
    // Détecter si c'est un ID ou un handle
    const isId = identifier.startsWith('prod_');
    const field = isId ? 'id' : 'handle';

    const result = await pool.query(`
      SELECT 
        p.*,
        JSON_AGG(
          JSON_BUILD_OBJECT(
            'id', pv.id,
            'title', pv.title,
            'sku', pv.sku,
            'price', pv.price,
            'compare_at_price', pv.compare_at_price,
            'inventory_quantity', pv.inventory_quantity,
            'inventory_policy', pv.inventory_policy,
            'option1', pv.option1,
            'option2', pv.option2,
            'option3', pv.option3,
            'weight', pv.weight,
            'requires_shipping', pv.requires_shipping
          )
        ) as variants
      FROM products p
      LEFT JOIN product_variants pv ON p.id = pv.product_id
      WHERE p.${field} = $1
      GROUP BY p.id
    `, [identifier]);

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Produit non trouvé'
      });
    }

    res.json({
      success: true,
      product: result.rows[0]
    });

  } catch (err) {
    console.error('❌ Erreur récupération produit:', err);
    res.status(500).json({
      success: false,
      error: 'Erreur lors de la récupération du produit'
    });
  }
});

// =====================================================
// API PRODUITS ADMIN - GESTION COMPLÈTE
// =====================================================

// Lister tous les produits (admin - avec tous les statuts)
app.get('/api/admin/products', authenticateAdmin, async (req, res) => {
  try {
    const { 
      limit = 50, 
      offset = 0, 
      status, 
      search,
      sort_by = 'created_at',
      sort_order = 'DESC'
    } = req.query;

    let whereClause = 'WHERE 1=1';
    const queryParams = [];
    let paramCount = 0;

    // Filtrer par statut
    if (status) {
      paramCount++;
      whereClause += ` AND p.status = $${paramCount}`;
      queryParams.push(status);
    }

    // Recherche textuelle
    if (search) {
      paramCount++;
      whereClause += ` AND (p.title ILIKE $${paramCount} OR p.description ILIKE $${paramCount})`;
      queryParams.push(`%${search}%`);
    }

    // Paramètres de pagination
    paramCount++;
    const limitParam = paramCount;
    queryParams.push(limit);

    paramCount++;
    const offsetParam = paramCount;
    queryParams.push(offset);

    const query = `
      SELECT 
        p.*,
        JSON_AGG(
          JSON_BUILD_OBJECT(
            'id', pv.id,
            'title', pv.title,
            'sku', pv.sku,
            'price', pv.price,
            'compare_at_price', pv.compare_at_price,
            'inventory_quantity', pv.inventory_quantity,
            'option1', pv.option1
          )
        ) as variants,
        (SELECT SUM(pv2.inventory_quantity) FROM product_variants pv2 WHERE pv2.product_id = p.id) as total_inventory
      FROM products p
      LEFT JOIN product_variants pv ON p.id = pv.product_id
      ${whereClause}
      GROUP BY p.id
      ORDER BY p.${sort_by} ${sort_order}
      LIMIT $${limitParam} OFFSET $${offsetParam}
    `;

    const result = await pool.query(query, queryParams);

    // Compter le total pour la pagination
    const countQuery = `
      SELECT COUNT(DISTINCT p.id) as total
      FROM products p
      ${whereClause.replace(/\$\d+$/, '').replace(/\$\d+$/, '')}
    `;
    const countResult = await pool.query(countQuery, queryParams.slice(0, -2));

    res.json({
      success: true,
      products: result.rows,
      pagination: {
        total: parseInt(countResult.rows[0].total),
        limit: parseInt(limit),
        offset: parseInt(offset),
        has_more: (parseInt(offset) + parseInt(limit)) < parseInt(countResult.rows[0].total)
      }
    });

  } catch (err) {
    console.error('❌ Erreur récupération produits admin:', err);
    res.status(500).json({
      success: false,
      error: 'Erreur lors de la récupération des produits'
    });
  }
});

// Créer un nouveau produit
app.post('/api/admin/products', authenticateAdmin, async (req, res) => {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const {
      title,
      description,
      status = 'draft',
      thumbnail,
      images = [],
      weight,
      length,
      width,
      height,
      origin_country = 'FR',
      material,
      seo_title,
      seo_description,
      metadata = {},
      variants = []
    } = req.body;

    if (!title) {
      return res.status(400).json({
        success: false,
        error: 'Le titre du produit est requis'
      });
    }

    // Générer l'ID et le handle
    const productId = generateProductId();
    const handle = title
      .toLowerCase()
      .normalize('NFD')
      .replace(/[\u0300-\u036f]/g, '') // supprimer les accents
      .replace(/[^a-z0-9]+/g, '-')
      .replace(/^-|-$/g, '');

    // Vérifier que le handle est unique
    const handleCheck = await client.query(
      'SELECT id FROM products WHERE handle = $1',
      [handle]
    );

    if (handleCheck.rows.length > 0) {
      return res.status(400).json({
        success: false,
        error: 'Un produit avec ce nom existe déjà'
      });
    }

    // Créer le produit
    const productResult = await client.query(`
      INSERT INTO products (
        id, title, handle, description, status, thumbnail, images,
        weight, length, width, height, origin_country, material,
        seo_title, seo_description, metadata
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16)
      RETURNING *
    `, [
      productId, title, handle, description, status, thumbnail, JSON.stringify(images),
      weight, length, width, height, origin_country, material,
      seo_title, seo_description, JSON.stringify(metadata)
    ]);

    const product = productResult.rows[0];

    // Créer les variants
    const createdVariants = [];
    if (variants.length > 0) {
      for (const variant of variants) {
        const variantId = generateVariantId();
        const variantResult = await client.query(`
          INSERT INTO product_variants (
            id, product_id, title, sku, price, compare_at_price, cost_price,
            inventory_quantity, inventory_policy, option1, option2, option3, weight
          ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13)
          RETURNING *
        `, [
          variantId, productId, variant.title, variant.sku, variant.price,
          variant.compare_at_price, variant.cost_price, variant.inventory_quantity || 0,
          variant.inventory_policy || 'deny', variant.option1, variant.option2,
          variant.option3, variant.weight
        ]);
        createdVariants.push(variantResult.rows[0]);
      }
    } else {
      // Créer un variant par défaut
      const variantId = generateVariantId();
      const defaultVariant = await client.query(`
        INSERT INTO product_variants (
          id, product_id, title, sku, price, inventory_quantity
        ) VALUES ($1, $2, $3, $4, $5, $6)
        RETURNING *
      `, [
        variantId, productId, 'Default', `${productId}-DEFAULT`, 0, 0
      ]);
      createdVariants.push(defaultVariant.rows[0]);
    }

    await client.query('COMMIT');

    // Logger la création
    await logAdminAction(req.admin.id, 'create_product', 'product', productId, {
      title,
      variants: createdVariants.length
    }, req);

    res.status(201).json({
      success: true,
      product: {
        ...product,
        variants: createdVariants
      },
      message: `Produit "${title}" créé avec succès`
    });

  } catch (err) {
    await client.query('ROLLBACK');
    console.error('❌ Erreur création produit:', err);
    res.status(500).json({
      success: false,
      error: 'Erreur lors de la création du produit'
    });
  } finally {
    client.release();
  }
});

// Modifier un produit existant
app.put('/api/admin/products/:id', authenticateAdmin, async (req, res) => {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const { id } = req.params;
    const updates = req.body;

    // Vérifier que le produit existe
    const existingProduct = await client.query(
      'SELECT * FROM products WHERE id = $1',
      [id]
    );

    if (existingProduct.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Produit non trouvé'
      });
    }

    // Construire la requête de mise à jour dynamiquement
    const updateFields = [];
    const updateValues = [];
    let paramCount = 0;

    const allowedFields = [
      'title', 'description', 'status', 'thumbnail', 'images',
      'weight', 'length', 'width', 'height', 'origin_country',
      'material', 'seo_title', 'seo_description', 'metadata',
      'display_sections'
    ];

    for (const [key, value] of Object.entries(updates)) {
      if (allowedFields.includes(key) && value !== undefined) {
        paramCount++;
        updateFields.push(`${key} = $${paramCount}`);
        updateValues.push(
          key === 'images' || key === 'metadata' 
            ? JSON.stringify(value) 
            : value
        );
      }
    }

    if (updateFields.length === 0) {
      return res.status(400).json({
        success: false,
        error: 'Aucune donnée à mettre à jour'
      });
    }

    // Ajouter la mise à jour du timestamp
    paramCount++;
    updateFields.push(`updated_at = $${paramCount}`);
    updateValues.push(new Date());

    // Ajouter l'ID pour la clause WHERE
    paramCount++;
    updateValues.push(id);

    const updateQuery = `
      UPDATE products 
      SET ${updateFields.join(', ')}
      WHERE id = $${paramCount}
      RETURNING *
    `;

    const result = await client.query(updateQuery, updateValues);

    await client.query('COMMIT');

    // Logger la modification
    await logAdminAction(req.admin.id, 'update_product', 'product', id, {
      updated_fields: Object.keys(updates)
    }, req);

    res.json({
      success: true,
      product: result.rows[0],
      message: 'Produit modifié avec succès'
    });

  } catch (err) {
    await client.query('ROLLBACK');
    console.error('❌ Erreur modification produit:', err);
    res.status(500).json({
      success: false,
      error: 'Erreur lors de la modification du produit'
    });
  } finally {
    client.release();
  }
});

// Supprimer un produit
app.delete('/api/admin/products/:id', authenticateAdmin, async (req, res) => {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const { id } = req.params;

    // Vérifier que le produit existe
    const existingProduct = await client.query(
      'SELECT title FROM products WHERE id = $1',
      [id]
    );

    if (existingProduct.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Produit non trouvé'
      });
    }

    const productTitle = existingProduct.rows[0].title;

    // Vérifier qu'il n'y a pas de commandes liées (optionnel - selon votre logique métier)
    const orderCheck = await client.query(
      'SELECT COUNT(*) as count FROM order_items WHERE product_id = $1',
      [id]
    );

    if (parseInt(orderCheck.rows[0].count) > 0) {
      return res.status(400).json({
        success: false,
        error: 'Impossible de supprimer un produit qui a des commandes associées'
      });
    }

    // Supprimer les variants (CASCADE devrait le faire automatiquement)
    await client.query('DELETE FROM product_variants WHERE product_id = $1', [id]);

    // Supprimer le produit
    await client.query('DELETE FROM products WHERE id = $1', [id]);

    await client.query('COMMIT');

    // Logger la suppression
    await logAdminAction(req.admin.id, 'delete_product', 'product', id, {
      title: productTitle
    }, req);

    res.json({
      success: true,
      message: `Produit "${productTitle}" supprimé avec succès`
    });

  } catch (err) {
    await client.query('ROLLBACK');
    console.error('❌ Erreur suppression produit:', err);
    res.status(500).json({
      success: false,
      error: 'Erreur lors de la suppression du produit'
    });
  } finally {
    client.release();
  }
});

// =====================================================
// GESTION DES VARIANTS
// =====================================================

// Créer un variant pour un produit
app.post('/api/admin/products/:productId/variants', authenticateAdmin, async (req, res) => {
  try {
    const { productId } = req.params;
    const {
      title,
      sku,
      price,
      compare_at_price,
      cost_price,
      inventory_quantity = 0,
      inventory_policy = 'deny',
      option1,
      option2,
      option3,
      weight
    } = req.body;

    if (!title || !price) {
      return res.status(400).json({
        success: false,
        error: 'Titre et prix du variant requis'
      });
    }

    // Vérifier que le produit existe
    const productCheck = await pool.query(
      'SELECT title FROM products WHERE id = $1',
      [productId]
    );

    if (productCheck.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Produit non trouvé'
      });
    }

    const variantId = generateVariantId();

    const result = await pool.query(`
      INSERT INTO product_variants (
        id, product_id, title, sku, price, compare_at_price, cost_price,
        inventory_quantity, inventory_policy, option1, option2, option3, weight
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13)
      RETURNING *
    `, [
      variantId, productId, title, sku, price, compare_at_price, cost_price,
      inventory_quantity, inventory_policy, option1, option2, option3, weight
    ]);

    // Logger la création
    await logAdminAction(req.admin.id, 'create_variant', 'variant', variantId, {
      product_id: productId,
      title
    }, req);

    res.status(201).json({
      success: true,
      variant: result.rows[0],
      message: `Variant "${title}" créé avec succès`
    });

  } catch (err) {
    console.error('❌ Erreur création variant:', err);
    res.status(500).json({
      success: false,
      error: 'Erreur lors de la création du variant'
    });
  }
});

// Modifier un variant
app.put('/api/admin/variants/:variantId', authenticateAdmin, async (req, res) => {
  try {
    const { variantId } = req.params;
    const updates = req.body;

    // Vérifier que le variant existe
    const existingVariant = await pool.query(
      'SELECT * FROM product_variants WHERE id = $1',
      [variantId]
    );

    if (existingVariant.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Variant non trouvé'
      });
    }

    // Construire la requête de mise à jour
    const updateFields = [];
    const updateValues = [];
    let paramCount = 0;

    const allowedFields = [
      'title', 'sku', 'price', 'compare_at_price', 'cost_price',
      'inventory_quantity', 'inventory_policy', 'option1', 'option2', 'option3', 'weight'
    ];

    for (const [key, value] of Object.entries(updates)) {
      if (allowedFields.includes(key) && value !== undefined) {
        paramCount++;
        updateFields.push(`${key} = $${paramCount}`);
        updateValues.push(value);
      }
    }

    if (updateFields.length === 0) {
      return res.status(400).json({
        success: false,
        error: 'Aucune donnée à mettre à jour'
      });
    }

    // Ajouter updated_at
    paramCount++;
    updateFields.push(`updated_at = $${paramCount}`);
    updateValues.push(new Date());

    // Ajouter l'ID pour WHERE
    paramCount++;
    updateValues.push(variantId);

    const updateQuery = `
      UPDATE product_variants 
      SET ${updateFields.join(', ')}
      WHERE id = $${paramCount}
      RETURNING *
    `;

    const result = await pool.query(updateQuery, updateValues);

    // Logger la modification
    await logAdminAction(req.admin.id, 'update_variant', 'variant', variantId, {
      updated_fields: Object.keys(updates)
    }, req);

    res.json({
      success: true,
      variant: result.rows[0],
      message: 'Variant modifié avec succès'
    });

  } catch (err) {
    console.error('❌ Erreur modification variant:', err);
    res.status(500).json({
      success: false,
      error: 'Erreur lors de la modification du variant'
    });
  }
});

// Supprimer un variant
app.delete('/api/admin/variants/:variantId', authenticateAdmin, async (req, res) => {
  try {
    const { variantId } = req.params;

    // Vérifier que le variant existe
    const existingVariant = await pool.query(
      'SELECT pv.title, p.title as product_title FROM product_variants pv JOIN products p ON pv.product_id = p.id WHERE pv.id = $1',
      [variantId]
    );

    if (existingVariant.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Variant non trouvé'
      });
    }

    const variant = existingVariant.rows[0];

    // Vérifier qu'il n'y a pas de commandes liées
    const orderCheck = await pool.query(
      'SELECT COUNT(*) as count FROM order_items WHERE variant_id = $1',
      [variantId]
    );

    if (parseInt(orderCheck.rows[0].count) > 0) {
      return res.status(400).json({
        success: false,
        error: 'Impossible de supprimer un variant qui a des commandes associées'
      });
    }

    // Supprimer le variant
    await pool.query('DELETE FROM product_variants WHERE id = $1', [variantId]);

    // Logger la suppression
    await logAdminAction(req.admin.id, 'delete_variant', 'variant', variantId, {
      title: variant.title,
      product_title: variant.product_title
    }, req);

    res.json({
      success: true,
      message: `Variant "${variant.title}" supprimé avec succès`
    });

  } catch (err) {
    console.error('❌ Erreur suppression variant:', err);
    res.status(500).json({
      success: false,
      error: 'Erreur lors de la suppression du variant'
    });
  }
});

module.exports = { app, pool, authenticateAdmin, logAdminAction };