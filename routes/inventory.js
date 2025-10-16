// =====================================================
// ROUTES GESTION DE L'INVENTAIRE
// =====================================================

// Système complet de gestion des stocks et mouvements d'inventaire

// =====================================================
// API INVENTAIRE ADMIN - GESTION COMPLÈTE
// =====================================================

// Tableau de bord inventaire avec alertes
app.get('/api/admin/inventory/dashboard', authenticateAdmin, async (req, res) => {
  try {
    // Statistiques générales du stock
    const stockStats = await pool.query(`
      SELECT 
        COUNT(DISTINCT pv.id) as total_variants,
        SUM(pv.inventory_quantity) as total_units_in_stock,
        COUNT(CASE WHEN pv.inventory_quantity <= 5 THEN 1 END) as low_stock_variants,
        COUNT(CASE WHEN pv.inventory_quantity = 0 THEN 1 END) as out_of_stock_variants,
        COALESCE(AVG(pv.inventory_quantity), 0) as avg_stock_per_variant,
        SUM(pv.inventory_quantity * pv.price) as total_inventory_value
      FROM product_variants pv
      WHERE pv.inventory_tracked = true
    `);

    // Alertes de stock faible
    const lowStockAlerts = await pool.query(`
      SELECT 
        pv.id,
        pv.title as variant_title,
        pv.sku,
        pv.inventory_quantity,
        pv.price,
        p.title as product_title,
        p.handle as product_handle
      FROM product_variants pv
      JOIN products p ON pv.product_id = p.id
      WHERE pv.inventory_tracked = true 
        AND pv.inventory_quantity <= 5
        AND pv.inventory_quantity > 0
      ORDER BY pv.inventory_quantity ASC
      LIMIT 20
    `);

    // Produits en rupture de stock
    const outOfStockProducts = await pool.query(`
      SELECT 
        pv.id,
        pv.title as variant_title,
        pv.sku,
        pv.price,
        p.title as product_title,
        p.handle as product_handle,
        (SELECT MAX(created_at) FROM inventory_movements 
         WHERE variant_id = pv.id AND quantity_change < 0) as last_sale_date
      FROM product_variants pv
      JOIN products p ON pv.product_id = p.id
      WHERE pv.inventory_tracked = true 
        AND pv.inventory_quantity = 0
      ORDER BY p.title ASC
      LIMIT 20
    `);

    // Mouvements récents (dernières 24h)
    const recentMovements = await pool.query(`
      SELECT 
        im.*,
        pv.title as variant_title,
        pv.sku,
        p.title as product_title,
        au.username as admin_name
      FROM inventory_movements im
      JOIN product_variants pv ON im.variant_id = pv.id
      JOIN products p ON pv.product_id = p.id
      LEFT JOIN admin_users au ON im.admin_id = au.id
      WHERE im.created_at >= CURRENT_TIMESTAMP - INTERVAL '24 hours'
      ORDER BY im.created_at DESC
      LIMIT 50
    `);

    await logAdminAction(req.admin.id, 'view_inventory_dashboard', 'inventory', null, {
      total_variants: stockStats.rows[0].total_variants,
      low_stock_count: stockStats.rows[0].low_stock_variants
    }, req);

    res.json({
      success: true,
      stats: stockStats.rows[0],
      alerts: {
        low_stock: lowStockAlerts.rows,
        out_of_stock: outOfStockProducts.rows
      },
      recent_movements: recentMovements.rows
    });

  } catch (err) {
    console.error('❌ Erreur dashboard inventaire:', err);
    res.status(500).json({
      success: false,
      error: 'Erreur lors de la récupération du dashboard inventaire'
    });
  }
});

// Lister tous les mouvements d'inventaire
app.get('/api/admin/inventory/movements', authenticateAdmin, async (req, res) => {
  try {
    const { 
      limit = 100, 
      offset = 0, 
      variant_id,
      reason,
      admin_id,
      date_from,
      date_to,
      sort_by = 'created_at',
      sort_order = 'DESC'
    } = req.query;

    let whereClause = 'WHERE 1=1';
    const queryParams = [];
    let paramCount = 0;

    if (variant_id) {
      paramCount++;
      whereClause += ` AND im.variant_id = $${paramCount}`;
      queryParams.push(variant_id);
    }

    if (reason) {
      paramCount++;
      whereClause += ` AND im.reason = $${paramCount}`;
      queryParams.push(reason);
    }

    if (admin_id) {
      paramCount++;
      whereClause += ` AND im.admin_id = $${paramCount}`;
      queryParams.push(admin_id);
    }

    if (date_from) {
      paramCount++;
      whereClause += ` AND im.created_at >= $${paramCount}`;
      queryParams.push(date_from);
    }

    if (date_to) {
      paramCount++;
      whereClause += ` AND im.created_at <= $${paramCount}`;
      queryParams.push(date_to);
    }

    paramCount++;
    queryParams.push(limit);
    paramCount++;
    queryParams.push(offset);

    const validSortFields = ['created_at', 'quantity_change', 'reason'];
    const sortField = validSortFields.includes(sort_by) ? sort_by : 'created_at';
    const sortDirection = sort_order.toLowerCase() === 'asc' ? 'ASC' : 'DESC';

    const query = `
      SELECT 
        im.*,
        pv.title as variant_title,
        pv.sku,
        pv.price,
        p.title as product_title,
        p.handle as product_handle,
        au.username as admin_name,
        au.email as admin_email
      FROM inventory_movements im
      JOIN product_variants pv ON im.variant_id = pv.id
      JOIN products p ON pv.product_id = p.id
      LEFT JOIN admin_users au ON im.admin_id = au.id
      ${whereClause}
      ORDER BY im.${sortField} ${sortDirection}
      LIMIT $${paramCount-1} OFFSET $${paramCount}
    `;

    const result = await pool.query(query, queryParams);

    // Compter le total
    const countQuery = `
      SELECT COUNT(*) as total
      FROM inventory_movements im
      ${whereClause}
    `;
    const countResult = await pool.query(countQuery, queryParams.slice(0, -2));

    res.json({
      success: true,
      movements: result.rows,
      pagination: {
        total: parseInt(countResult.rows[0].total),
        limit: parseInt(limit),
        offset: parseInt(offset),
        has_more: (parseInt(offset) + parseInt(limit)) < parseInt(countResult.rows[0].total)
      }
    });

  } catch (err) {
    console.error('❌ Erreur mouvements inventaire:', err);
    res.status(500).json({
      success: false,
      error: 'Erreur lors de la récupération des mouvements'
    });
  }
});

// Ajuster le stock d'un variant (admin)
app.post('/api/admin/inventory/adjust', authenticateAdmin, async (req, res) => {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const {
      variant_id,
      quantity_change,
      reason = 'adjustment',
      note = '',
      new_quantity // Optionnel : pour définir une quantité absolue
    } = req.body;

    if (!variant_id) {
      return res.status(400).json({
        success: false,
        error: 'variant_id est requis'
      });
    }

    // Récupérer le variant actuel
    const variantResult = await client.query(
      'SELECT * FROM product_variants WHERE id = $1',
      [variant_id]
    );

    if (variantResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Variant non trouvé'
      });
    }

    const variant = variantResult.rows[0];
    let actualQuantityChange = quantity_change;

    // Si new_quantity est défini, calculer le changement
    if (new_quantity !== undefined) {
      actualQuantityChange = new_quantity - variant.inventory_quantity;
    }

    if (actualQuantityChange === 0) {
      return res.status(400).json({
        success: false,
        error: 'Aucun changement de stock nécessaire'
      });
    }

    const newQuantity = variant.inventory_quantity + actualQuantityChange;

    if (newQuantity < 0) {
      return res.status(400).json({
        success: false,
        error: 'La quantité ne peut pas être négative'
      });
    }

    // Mettre à jour le stock
    await client.query(`
      UPDATE product_variants 
      SET inventory_quantity = $1, updated_at = CURRENT_TIMESTAMP
      WHERE id = $2
    `, [newQuantity, variant_id]);

    // Enregistrer le mouvement
    await client.query(`
      INSERT INTO inventory_movements (
        variant_id, quantity_change, quantity_before, quantity_after,
        reason, reference_type, reference_id, note, admin_id
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
    `, [
      variant_id, actualQuantityChange, variant.inventory_quantity, newQuantity,
      reason, 'manual_adjustment', null, note, req.admin.id
    ]);

    await client.query('COMMIT');

    // Récupérer les infos du produit pour le log
    const productInfo = await pool.query(`
      SELECT p.title as product_title, pv.title as variant_title, pv.sku
      FROM product_variants pv
      JOIN products p ON pv.product_id = p.id
      WHERE pv.id = $1
    `, [variant_id]);

    await logAdminAction(req.admin.id, 'adjust_inventory', 'inventory', variant_id, {
      product_title: productInfo.rows[0].product_title,
      variant_title: productInfo.rows[0].variant_title,
      sku: productInfo.rows[0].sku,
      old_quantity: variant.inventory_quantity,
      new_quantity: newQuantity,
      change: actualQuantityChange,
      reason,
      note
    }, req);

    res.json({
      success: true,
      message: 'Stock ajusté avec succès',
      adjustment: {
        variant_id,
        old_quantity: variant.inventory_quantity,
        new_quantity: newQuantity,
        change: actualQuantityChange,
        reason,
        note
      }
    });

  } catch (err) {
    await client.query('ROLLBACK');
    console.error('❌ Erreur ajustement stock:', err);
    res.status(500).json({
      success: false,
      error: 'Erreur lors de l\'ajustement du stock'
    });
  } finally {
    client.release();
  }
});

// Rapport d'inventaire avec valeurs
app.get('/api/admin/inventory/report', authenticateAdmin, async (req, res) => {
  try {
    const { 
      format = 'summary', // 'summary' ou 'detailed'
      include_zero_stock = false,
      product_id
    } = req.query;

    let whereClause = 'WHERE pv.inventory_tracked = true';
    const queryParams = [];
    let paramCount = 0;

    if (!include_zero_stock) {
      whereClause += ' AND pv.inventory_quantity > 0';
    }

    if (product_id) {
      paramCount++;
      whereClause += ` AND p.id = $${paramCount}`;
      queryParams.push(product_id);
    }

    let query;
    if (format === 'detailed') {
      query = `
        SELECT 
          p.id as product_id,
          p.title as product_title,
          p.handle as product_handle,
          pv.id as variant_id,
          pv.title as variant_title,
          pv.sku,
          pv.price,
          pv.inventory_quantity,
          (pv.inventory_quantity * pv.price) as inventory_value,
          pv.inventory_policy,
          pv.created_at as variant_created_at,
          (SELECT COUNT(*) FROM order_items oi 
           JOIN orders o ON oi.order_id = o.id 
           WHERE oi.variant_id = pv.id 
           AND o.created_at >= CURRENT_DATE - INTERVAL '30 days') as sales_last_30_days,
          (SELECT COALESCE(SUM(oi.quantity), 0) FROM order_items oi 
           JOIN orders o ON oi.order_id = o.id 
           WHERE oi.variant_id = pv.id 
           AND o.created_at >= CURRENT_DATE - INTERVAL '30 days') as units_sold_last_30_days
        FROM product_variants pv
        JOIN products p ON pv.product_id = p.id
        ${whereClause}
        ORDER BY p.title ASC, pv.title ASC
      `;
    } else {
      query = `
        SELECT 
          p.id as product_id,
          p.title as product_title,
          COUNT(pv.id) as total_variants,
          SUM(pv.inventory_quantity) as total_quantity,
          SUM(pv.inventory_quantity * pv.price) as total_value,
          AVG(pv.price) as avg_price,
          MIN(pv.inventory_quantity) as min_stock,
          MAX(pv.inventory_quantity) as max_stock
        FROM product_variants pv
        JOIN products p ON pv.product_id = p.id
        ${whereClause}
        GROUP BY p.id, p.title
        ORDER BY total_value DESC
      `;
    }

    const result = await pool.query(query, queryParams);

    // Statistiques globales
    const globalStats = await pool.query(`
      SELECT 
        COUNT(DISTINCT p.id) as total_products,
        COUNT(pv.id) as total_variants,
        SUM(pv.inventory_quantity) as total_units,
        SUM(pv.inventory_quantity * pv.price) as total_inventory_value,
        AVG(pv.inventory_quantity) as avg_stock_per_variant
      FROM product_variants pv
      JOIN products p ON pv.product_id = p.id
      WHERE pv.inventory_tracked = true
    `);

    await logAdminAction(req.admin.id, 'generate_inventory_report', 'inventory', null, {
      format,
      include_zero_stock,
      product_id,
      items_count: result.rows.length
    }, req);

    res.json({
      success: true,
      report: {
        format,
        generated_at: new Date(),
        global_stats: globalStats.rows[0],
        items: result.rows
      }
    });

  } catch (err) {
    console.error('❌ Erreur rapport inventaire:', err);
    res.status(500).json({
      success: false,
      error: 'Erreur lors de la génération du rapport'
    });
  }
});

// Historique d'un variant spécifique
app.get('/api/admin/inventory/variants/:id/history', authenticateAdmin, async (req, res) => {
  try {
    const { id } = req.params;
    const { limit = 50, offset = 0 } = req.query;

    // Vérifier que le variant existe
    const variantCheck = await pool.query(`
      SELECT pv.*, p.title as product_title
      FROM product_variants pv
      JOIN products p ON pv.product_id = p.id
      WHERE pv.id = $1
    `, [id]);

    if (variantCheck.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Variant non trouvé'
      });
    }

    const variant = variantCheck.rows[0];

    // Récupérer l'historique des mouvements
    const movements = await pool.query(`
      SELECT 
        im.*,
        au.username as admin_name,
        au.email as admin_email
      FROM inventory_movements im
      LEFT JOIN admin_users au ON im.admin_id = au.id
      WHERE im.variant_id = $1
      ORDER BY im.created_at DESC
      LIMIT $2 OFFSET $3
    `, [id, limit, offset]);

    // Compter le total
    const countResult = await pool.query(
      'SELECT COUNT(*) as total FROM inventory_movements WHERE variant_id = $1',
      [id]
    );

    res.json({
      success: true,
      variant: {
        id: variant.id,
        title: variant.title,
        sku: variant.sku,
        product_title: variant.product_title,
        current_quantity: variant.inventory_quantity,
        price: variant.price
      },
      movements: movements.rows,
      pagination: {
        total: parseInt(countResult.rows[0].total),
        limit: parseInt(limit),
        offset: parseInt(offset),
        has_more: (parseInt(offset) + parseInt(limit)) < parseInt(countResult.rows[0].total)
      }
    });

  } catch (err) {
    console.error('❌ Erreur historique variant:', err);
    res.status(500).json({
      success: false,
      error: 'Erreur lors de la récupération de l\'historique'
    });
  }
});

module.exports = { app, pool, authenticateAdmin, logAdminAction };