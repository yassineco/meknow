// =====================================================
// ROUTES GESTION DES COMMANDES
// =====================================================

// Ajouter ceci au backend-v2.js après les routes produits

// =====================================================
// API COMMANDES - LECTURE
// =====================================================

// Créer une nouvelle commande (depuis le frontend)
app.post('/api/orders', async (req, res) => {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const {
      customer_email,
      customer_first_name,
      customer_last_name,
      customer_phone,
      billing_address,
      shipping_address,
      items, // [{ variant_id, quantity }]
      shipping_method = 'standard',
      payment_method = 'cod',
      customer_note = ''
    } = req.body;

    // Validation des données requises
    if (!customer_email || !billing_address || !shipping_address || !items || items.length === 0) {
      return res.status(400).json({
        success: false,
        error: 'Données de commande incomplètes'
      });
    }

    // Créer ou récupérer le client
    let customer;
    const existingCustomer = await client.query(
      'SELECT * FROM customers WHERE email = $1',
      [customer_email]
    );

    if (existingCustomer.rows.length > 0) {
      customer = existingCustomer.rows[0];
      // Mettre à jour les infos si nécessaire
      await client.query(`
        UPDATE customers 
        SET first_name = $1, last_name = $2, phone = $3, updated_at = CURRENT_TIMESTAMP
        WHERE id = $4
      `, [customer_first_name, customer_last_name, customer_phone, customer.id]);
    } else {
      // Créer un nouveau client
      const newCustomer = await client.query(`
        INSERT INTO customers (email, first_name, last_name, phone, billing_address, shipping_address)
        VALUES ($1, $2, $3, $4, $5, $6)
        RETURNING *
      `, [
        customer_email, customer_first_name, customer_last_name, customer_phone,
        JSON.stringify(billing_address), JSON.stringify(shipping_address)
      ]);
      customer = newCustomer.rows[0];
    }

    // Vérifier la disponibilité des produits et calculer les montants
    let subtotal = 0;
    const orderItems = [];

    for (const item of items) {
      const variant = await client.query(`
        SELECT pv.*, p.title as product_title
        FROM product_variants pv
        JOIN products p ON pv.product_id = p.id
        WHERE pv.id = $1
      `, [item.variant_id]);

      if (variant.rows.length === 0) {
        throw new Error(`Variant ${item.variant_id} non trouvé`);
      }

      const variantData = variant.rows[0];

      // Vérifier le stock
      if (variantData.inventory_quantity < item.quantity && variantData.inventory_policy === 'deny') {
        throw new Error(`Stock insuffisant pour ${variantData.product_title} - ${variantData.title}`);
      }

      const lineTotal = variantData.price * item.quantity;
      subtotal += lineTotal;

      orderItems.push({
        product_id: variantData.product_id,
        variant_id: variantData.id,
        quantity: item.quantity,
        price: variantData.price,
        total: lineTotal,
        product_title: variantData.product_title,
        variant_title: variantData.title,
        sku: variantData.sku
      });
    }

    // Calculer les taxes et frais
    const taxRate = 0.20; // 20% TVA
    const totalTax = Math.round(subtotal * taxRate);
    const shippingCost = 0; // Livraison gratuite
    const total = subtotal + totalTax + shippingCost;

    // Générer le numéro de commande
    const orderNumber = generateOrderNumber();

    // Créer la commande
    const orderResult = await client.query(`
      INSERT INTO orders (
        order_number, customer_id, billing_address, shipping_address,
        subtotal, total_tax, shipping_cost, total,
        payment_method, payment_status, shipping_method,
        customer_note, source_name
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13)
      RETURNING *
    `, [
      orderNumber, customer.id,
      JSON.stringify(billing_address), JSON.stringify(shipping_address),
      subtotal, totalTax, shippingCost, total,
      payment_method, 'pending', shipping_method,
      customer_note, 'web'
    ]);

    const order = orderResult.rows[0];

    // Créer les lignes de commande
    for (const item of orderItems) {
      await client.query(`
        INSERT INTO order_items (
          order_id, product_id, variant_id, quantity, price, total,
          product_title, variant_title, sku
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
      `, [
        order.id, item.product_id, item.variant_id, item.quantity,
        item.price, item.total, item.product_title, item.variant_title, item.sku
      ]);

      // Décrémenter le stock
      await client.query(`
        UPDATE product_variants 
        SET inventory_quantity = inventory_quantity - $1,
            updated_at = CURRENT_TIMESTAMP
        WHERE id = $2
      `, [item.quantity, item.variant_id]);

      // Enregistrer le mouvement de stock
      await client.query(`
        INSERT INTO inventory_movements (
          variant_id, quantity_change, quantity_before, quantity_after,
          reason, reference_type, reference_id, note
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
      `, [
        item.variant_id, -item.quantity, 
        item.inventory_quantity, item.inventory_quantity - item.quantity,
        'sale', 'order', order.id.toString(), `Commande ${orderNumber}`
      ]);
    }

    // Mettre à jour les statistiques client
    await client.query(`
      UPDATE customers 
      SET orders_count = orders_count + 1,
          total_spent = total_spent + $1,
          last_order_at = CURRENT_TIMESTAMP
      WHERE id = $2
    `, [total, customer.id]);

    await client.query('COMMIT');

    // Réponse avec détails de la commande
    res.status(201).json({
      success: true,
      order: {
        id: order.id,
        order_number: orderNumber,
        total: total,
        currency: 'EUR',
        payment_method,
        payment_status: 'pending',
        customer: {
          email: customer_email,
          name: `${customer_first_name} ${customer_last_name}`
        }
      },
      message: `Commande ${orderNumber} créée avec succès`
    });

  } catch (err) {
    await client.query('ROLLBACK');
    console.error('❌ Erreur création commande:', err);
    res.status(500).json({
      success: false,
      error: err.message || 'Erreur lors de la création de la commande'
    });
  } finally {
    client.release();
  }
});

// =====================================================
// API COMMANDES ADMIN - GESTION COMPLÈTE
// =====================================================

// Lister toutes les commandes (admin)
app.get('/api/admin/orders', authenticateAdmin, async (req, res) => {
  try {
    const { 
      limit = 50, 
      offset = 0, 
      status, 
      payment_status,
      fulfillment_status,
      search,
      sort_by = 'created_at',
      sort_order = 'DESC'
    } = req.query;

    let whereClause = 'WHERE 1=1';
    const queryParams = [];
    let paramCount = 0;

    // Filtres
    if (status) {
      paramCount++;
      whereClause += ` AND o.fulfillment_status = $${paramCount}`;
      queryParams.push(status);
    }

    if (payment_status) {
      paramCount++;
      whereClause += ` AND o.financial_status = $${paramCount}`;
      queryParams.push(payment_status);
    }

    if (search) {
      paramCount++;
      whereClause += ` AND (o.order_number ILIKE $${paramCount} OR c.email ILIKE $${paramCount} OR c.first_name ILIKE $${paramCount} OR c.last_name ILIKE $${paramCount})`;
      queryParams.push(`%${search}%`);
    }

    // Pagination
    paramCount++;
    const limitParam = paramCount;
    queryParams.push(limit);

    paramCount++;
    const offsetParam = paramCount;
    queryParams.push(offset);

    const query = `
      SELECT 
        o.*,
        c.email as customer_email,
        c.first_name as customer_first_name,
        c.last_name as customer_last_name,
        c.phone as customer_phone,
        (SELECT COUNT(*) FROM order_items WHERE order_id = o.id) as items_count,
        (SELECT JSON_AGG(
          JSON_BUILD_OBJECT(
            'id', oi.id,
            'product_title', oi.product_title,
            'variant_title', oi.variant_title,
            'quantity', oi.quantity,
            'price', oi.price,
            'total', oi.total
          )
        ) FROM order_items oi WHERE oi.order_id = o.id) as items
      FROM orders o
      LEFT JOIN customers c ON o.customer_id = c.id
      ${whereClause}
      ORDER BY o.${sort_by} ${sort_order}
      LIMIT $${limitParam} OFFSET $${offsetParam}
    `;

    const result = await pool.query(query, queryParams);

    // Compter le total
    const countQuery = `
      SELECT COUNT(*) as total
      FROM orders o
      LEFT JOIN customers c ON o.customer_id = c.id
      ${whereClause.replace(/\$\d+$/, '').replace(/\$\d+$/, '')}
    `;
    const countResult = await pool.query(countQuery, queryParams.slice(0, -2));

    res.json({
      success: true,
      orders: result.rows,
      pagination: {
        total: parseInt(countResult.rows[0].total),
        limit: parseInt(limit),
        offset: parseInt(offset),
        has_more: (parseInt(offset) + parseInt(limit)) < parseInt(countResult.rows[0].total)
      }
    });

  } catch (err) {
    console.error('❌ Erreur récupération commandes:', err);
    res.status(500).json({
      success: false,
      error: 'Erreur lors de la récupération des commandes'
    });
  }
});

// Récupérer une commande par ID
app.get('/api/admin/orders/:id', authenticateAdmin, async (req, res) => {
  try {
    const { id } = req.params;

    const result = await pool.query(`
      SELECT 
        o.*,
        c.email as customer_email,
        c.first_name as customer_first_name,
        c.last_name as customer_last_name,
        c.phone as customer_phone,
        c.orders_count as customer_orders_count,
        c.total_spent as customer_total_spent,
        (SELECT JSON_AGG(
          JSON_BUILD_OBJECT(
            'id', oi.id,
            'product_id', oi.product_id,
            'variant_id', oi.variant_id,
            'product_title', oi.product_title,
            'variant_title', oi.variant_title,
            'sku', oi.sku,
            'quantity', oi.quantity,
            'price', oi.price,
            'total', oi.total
          )
        ) FROM order_items oi WHERE oi.order_id = o.id) as items
      FROM orders o
      LEFT JOIN customers c ON o.customer_id = c.id
      WHERE o.id = $1
    `, [id]);

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Commande non trouvée'
      });
    }

    res.json({
      success: true,
      order: result.rows[0]
    });

  } catch (err) {
    console.error('❌ Erreur récupération commande:', err);
    res.status(500).json({
      success: false,
      error: 'Erreur lors de la récupération de la commande'
    });
  }
});

// Mettre à jour le statut d'une commande
app.put('/api/admin/orders/:id/status', authenticateAdmin, async (req, res) => {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const { id } = req.params;
    const { 
      fulfillment_status, 
      financial_status, 
      tracking_number, 
      carrier,
      note 
    } = req.body;

    // Vérifier que la commande existe
    const existingOrder = await client.query(
      'SELECT * FROM orders WHERE id = $1',
      [id]
    );

    if (existingOrder.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Commande non trouvée'
      });
    }

    const order = existingOrder.rows[0];
    const updates = [];
    const values = [];
    let paramCount = 0;

    // Construire la requête de mise à jour
    if (fulfillment_status) {
      paramCount++;
      updates.push(`fulfillment_status = $${paramCount}`);
      values.push(fulfillment_status);

      // Mettre à jour les dates selon le statut
      if (fulfillment_status === 'fulfilled' && !order.shipped_at) {
        paramCount++;
        updates.push(`shipped_at = $${paramCount}`);
        values.push(new Date());
      }
    }

    if (financial_status) {
      paramCount++;
      updates.push(`financial_status = $${paramCount}`);
      values.push(financial_status);

      if (financial_status === 'paid' && !order.processed_at) {
        paramCount++;
        updates.push(`processed_at = $${paramCount}`);
        values.push(new Date());
      }
    }

    if (tracking_number) {
      paramCount++;
      updates.push(`tracking_number = $${paramCount}`);
      values.push(tracking_number);
    }

    if (carrier) {
      paramCount++;
      updates.push(`carrier = $${paramCount}`);
      values.push(carrier);
    }

    if (note) {
      paramCount++;
      updates.push(`note = $${paramCount}`);
      values.push(note);
    }

    // Toujours mettre à jour updated_at
    paramCount++;
    updates.push(`updated_at = $${paramCount}`);
    values.push(new Date());

    // Ajouter l'ID pour la clause WHERE
    paramCount++;
    values.push(id);

    const updateQuery = `
      UPDATE orders 
      SET ${updates.join(', ')}
      WHERE id = $${paramCount}
      RETURNING *
    `;

    const result = await client.query(updateQuery, values);

    await client.query('COMMIT');

    // Logger la modification
    await logAdminAction(req.admin.id, 'update_order_status', 'order', id, {
      old_fulfillment_status: order.fulfillment_status,
      new_fulfillment_status: fulfillment_status,
      old_financial_status: order.financial_status,
      new_financial_status: financial_status,
      tracking_number,
      carrier
    }, req);

    res.json({
      success: true,
      order: result.rows[0],
      message: 'Statut de la commande mis à jour avec succès'
    });

  } catch (err) {
    await client.query('ROLLBACK');
    console.error('❌ Erreur mise à jour statut commande:', err);
    res.status(500).json({
      success: false,
      error: 'Erreur lors de la mise à jour du statut'
    });
  } finally {
    client.release();
  }
});

// Annuler une commande
app.post('/api/admin/orders/:id/cancel', authenticateAdmin, async (req, res) => {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const { id } = req.params;
    const { reason, refund_amount } = req.body;

    // Récupérer la commande avec ses items
    const orderResult = await client.query(`
      SELECT o.*, 
        JSON_AGG(
          JSON_BUILD_OBJECT(
            'variant_id', oi.variant_id,
            'quantity', oi.quantity
          )
        ) as items
      FROM orders o
      LEFT JOIN order_items oi ON o.id = oi.order_id
      WHERE o.id = $1
      GROUP BY o.id
    `, [id]);

    if (orderResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Commande non trouvée'
      });
    }

    const order = orderResult.rows[0];

    if (order.fulfillment_status === 'fulfilled') {
      return res.status(400).json({
        success: false,
        error: 'Impossible d\'annuler une commande déjà expédiée'
      });
    }

    // Remettre le stock
    for (const item of order.items) {
      if (item.variant_id) {
        await client.query(`
          UPDATE product_variants 
          SET inventory_quantity = inventory_quantity + $1,
              updated_at = CURRENT_TIMESTAMP
          WHERE id = $2
        `, [item.quantity, item.variant_id]);

        // Enregistrer le mouvement de stock
        await client.query(`
          INSERT INTO inventory_movements (
            variant_id, quantity_change, quantity_before, quantity_after,
            reason, reference_type, reference_id, note, admin_id
          ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
        `, [
          item.variant_id, item.quantity, 
          0, item.quantity, // TODO: récupérer les vraies quantités
          'return', 'order_cancel', order.id.toString(), 
          `Annulation commande ${order.order_number}`, req.admin.id
        ]);
      }
    }

    // Mettre à jour la commande
    await client.query(`
      UPDATE orders 
      SET fulfillment_status = 'unfulfilled',
          financial_status = 'voided',
          cancelled_at = CURRENT_TIMESTAMP,
          cancel_reason = $1,
          updated_at = CURRENT_TIMESTAMP
      WHERE id = $2
    `, [reason, id]);

    // Mettre à jour les stats client
    await client.query(`
      UPDATE customers 
      SET orders_count = orders_count - 1,
          total_spent = total_spent - $1
      WHERE id = $2
    `, [order.total, order.customer_id]);

    await client.query('COMMIT');

    // Logger l'annulation
    await logAdminAction(req.admin.id, 'cancel_order', 'order', id, {
      order_number: order.order_number,
      reason,
      refund_amount
    }, req);

    res.json({
      success: true,
      message: `Commande ${order.order_number} annulée avec succès`
    });

  } catch (err) {
    await client.query('ROLLBACK');
    console.error('❌ Erreur annulation commande:', err);
    res.status(500).json({
      success: false,
      error: 'Erreur lors de l\'annulation de la commande'
    });
  } finally {
    client.release();
  }
});

module.exports = { app, pool, authenticateAdmin, logAdminAction };