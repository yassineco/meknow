// =====================================================
// ROUTES GESTION DES CLIENTS
// =====================================================

// Routes pour la gestion complète des clients dans l'interface admin

// =====================================================
// API CLIENTS ADMIN - GESTION COMPLÈTE
// =====================================================

// Lister tous les clients (admin)
app.get('/api/admin/customers', authenticateAdmin, async (req, res) => {
  try {
    const { 
      limit = 50, 
      offset = 0, 
      search,
      sort_by = 'created_at',
      sort_order = 'DESC',
      min_orders = 0,
      min_spent = 0
    } = req.query;

    let whereClause = 'WHERE 1=1';
    const queryParams = [];
    let paramCount = 0;

    // Filtres de recherche
    if (search) {
      paramCount++;
      whereClause += ` AND (c.email ILIKE $${paramCount} OR c.first_name ILIKE $${paramCount} OR c.last_name ILIKE $${paramCount} OR c.phone ILIKE $${paramCount})`;
      queryParams.push(`%${search}%`);
    }

    if (min_orders > 0) {
      paramCount++;
      whereClause += ` AND c.orders_count >= $${paramCount}`;
      queryParams.push(min_orders);
    }

    if (min_spent > 0) {
      paramCount++;
      whereClause += ` AND c.total_spent >= $${paramCount}`;
      queryParams.push(min_spent);
    }

    // Pagination
    paramCount++;
    queryParams.push(limit);
    paramCount++;
    queryParams.push(offset);

    const validSortFields = ['created_at', 'email', 'first_name', 'last_name', 'orders_count', 'total_spent', 'last_order_at'];
    const sortField = validSortFields.includes(sort_by) ? sort_by : 'created_at';
    const sortDirection = sort_order.toLowerCase() === 'asc' ? 'ASC' : 'DESC';

    const query = `
      SELECT 
        c.*,
        (SELECT MAX(created_at) FROM orders WHERE customer_id = c.id) as last_order_date,
        (SELECT JSON_AGG(
          JSON_BUILD_OBJECT(
            'id', o.id,
            'order_number', o.order_number,
            'total', o.total,
            'created_at', o.created_at,
            'fulfillment_status', o.fulfillment_status,
            'financial_status', o.financial_status
          ) ORDER BY o.created_at DESC
        ) FROM orders o WHERE o.customer_id = c.id LIMIT 5) as recent_orders
      FROM customers c
      ${whereClause}
      ORDER BY c.${sortField} ${sortDirection}
      LIMIT $${paramCount-1} OFFSET $${paramCount}
    `;

    const result = await pool.query(query, queryParams);

    // Compter le total
    const countQuery = `
      SELECT COUNT(*) as total
      FROM customers c
      ${whereClause}
    `;
    const countResult = await pool.query(countQuery, queryParams.slice(0, -2));

    await logAdminAction(req.admin.id, 'view_customers', 'customers', null, {
      filters: { search, min_orders, min_spent },
      count: result.rows.length
    }, req);

    res.json({
      success: true,
      customers: result.rows,
      pagination: {
        total: parseInt(countResult.rows[0].total),
        limit: parseInt(limit),
        offset: parseInt(offset),
        has_more: (parseInt(offset) + parseInt(limit)) < parseInt(countResult.rows[0].total)
      }
    });

  } catch (err) {
    console.error('❌ Erreur récupération clients:', err);
    res.status(500).json({
      success: false,
      error: 'Erreur lors de la récupération des clients'
    });
  }
});

// Récupérer un client par ID avec historique complet
app.get('/api/admin/customers/:id', authenticateAdmin, async (req, res) => {
  try {
    const { id } = req.params;

    const result = await pool.query(`
      SELECT 
        c.*,
        (SELECT COUNT(*) FROM orders WHERE customer_id = c.id) as total_orders,
        (SELECT COALESCE(SUM(total), 0) FROM orders WHERE customer_id = c.id) as lifetime_value,
        (SELECT AVG(total) FROM orders WHERE customer_id = c.id) as average_order_value,
        (SELECT JSON_AGG(
          JSON_BUILD_OBJECT(
            'id', o.id,
            'order_number', o.order_number,
            'total', o.total,
            'subtotal', o.subtotal,
            'tax', o.total_tax,
            'shipping', o.shipping_cost,
            'created_at', o.created_at,
            'fulfillment_status', o.fulfillment_status,
            'financial_status', o.financial_status,
            'payment_method', o.payment_method,
            'items_count', (SELECT COUNT(*) FROM order_items WHERE order_id = o.id)
          ) ORDER BY o.created_at DESC
        ) FROM orders o WHERE o.customer_id = c.id) as order_history
      FROM customers c
      WHERE c.id = $1
    `, [id]);

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Client non trouvé'
      });
    }

    const customer = result.rows[0];

    // Récupérer les produits les plus achetés par ce client
    const topProducts = await pool.query(`
      SELECT 
        oi.product_title,
        oi.variant_title,
        SUM(oi.quantity) as total_quantity,
        SUM(oi.total) as total_spent,
        COUNT(DISTINCT oi.order_id) as times_ordered
      FROM order_items oi
      JOIN orders o ON oi.order_id = o.id
      WHERE o.customer_id = $1
      GROUP BY oi.product_title, oi.variant_title
      ORDER BY total_quantity DESC
      LIMIT 10
    `, [id]);

    customer.top_products = topProducts.rows;

    await logAdminAction(req.admin.id, 'view_customer', 'customer', id, {
      customer_email: customer.email,
      orders_count: customer.orders_count
    }, req);

    res.json({
      success: true,
      customer: customer
    });

  } catch (err) {
    console.error('❌ Erreur récupération client:', err);
    res.status(500).json({
      success: false,
      error: 'Erreur lors de la récupération du client'
    });
  }
});

// Créer un nouveau client (admin)
app.post('/api/admin/customers', authenticateAdmin, async (req, res) => {
  try {
    const {
      email,
      first_name,
      last_name,
      phone,
      billing_address,
      shipping_address,
      note,
      tags = []
    } = req.body;

    // Validation des données requises
    if (!email || !first_name || !last_name) {
      return res.status(400).json({
        success: false,
        error: 'Email, prénom et nom sont requis'
      });
    }

    // Vérifier que l'email n'existe pas déjà
    const existingCustomer = await pool.query(
      'SELECT id FROM customers WHERE email = $1',
      [email.toLowerCase()]
    );

    if (existingCustomer.rows.length > 0) {
      return res.status(400).json({
        success: false,
        error: 'Un client avec cet email existe déjà'
      });
    }

    const result = await pool.query(`
      INSERT INTO customers (
        email, first_name, last_name, phone, 
        billing_address, shipping_address, note, tags
      )
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
      RETURNING *
    `, [
      email.toLowerCase(),
      first_name,
      last_name,
      phone,
      billing_address ? JSON.stringify(billing_address) : null,
      shipping_address ? JSON.stringify(shipping_address) : null,
      note,
      JSON.stringify(tags)
    ]);

    await logAdminAction(req.admin.id, 'create_customer', 'customer', result.rows[0].id, {
      email: email.toLowerCase(),
      name: `${first_name} ${last_name}`
    }, req);

    res.status(201).json({
      success: true,
      customer: result.rows[0],
      message: 'Client créé avec succès'
    });

  } catch (err) {
    console.error('❌ Erreur création client:', err);
    res.status(500).json({
      success: false,
      error: 'Erreur lors de la création du client'
    });
  }
});

// Modifier un client (admin)
app.put('/api/admin/customers/:id', authenticateAdmin, async (req, res) => {
  try {
    const { id } = req.params;
    const {
      email,
      first_name,
      last_name,
      phone,
      billing_address,
      shipping_address,
      note,
      tags = []
    } = req.body;

    // Vérifier que le client existe
    const existingCustomer = await pool.query(
      'SELECT * FROM customers WHERE id = $1',
      [id]
    );

    if (existingCustomer.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Client non trouvé'
      });
    }

    // Si l'email change, vérifier qu'il n'existe pas déjà
    if (email && email.toLowerCase() !== existingCustomer.rows[0].email) {
      const emailCheck = await pool.query(
        'SELECT id FROM customers WHERE email = $1 AND id != $2',
        [email.toLowerCase(), id]
      );

      if (emailCheck.rows.length > 0) {
        return res.status(400).json({
          success: false,
          error: 'Un autre client avec cet email existe déjà'
        });
      }
    }

    const updates = [];
    const values = [];
    let paramCount = 0;

    if (email) {
      paramCount++;
      updates.push(`email = $${paramCount}`);
      values.push(email.toLowerCase());
    }

    if (first_name) {
      paramCount++;
      updates.push(`first_name = $${paramCount}`);
      values.push(first_name);
    }

    if (last_name) {
      paramCount++;
      updates.push(`last_name = $${paramCount}`);
      values.push(last_name);
    }

    if (phone !== undefined) {
      paramCount++;
      updates.push(`phone = $${paramCount}`);
      values.push(phone);
    }

    if (billing_address !== undefined) {
      paramCount++;
      updates.push(`billing_address = $${paramCount}`);
      values.push(billing_address ? JSON.stringify(billing_address) : null);
    }

    if (shipping_address !== undefined) {
      paramCount++;
      updates.push(`shipping_address = $${paramCount}`);
      values.push(shipping_address ? JSON.stringify(shipping_address) : null);
    }

    if (note !== undefined) {
      paramCount++;
      updates.push(`note = $${paramCount}`);
      values.push(note);
    }

    if (tags !== undefined) {
      paramCount++;
      updates.push(`tags = $${paramCount}`);
      values.push(JSON.stringify(tags));
    }

    if (updates.length === 0) {
      return res.status(400).json({
        success: false,
        error: 'Aucune donnée à modifier'
      });
    }

    // Ajouter updated_at
    paramCount++;
    updates.push(`updated_at = $${paramCount}`);
    values.push(new Date());

    // Ajouter l'ID pour WHERE
    paramCount++;
    values.push(id);

    const updateQuery = `
      UPDATE customers 
      SET ${updates.join(', ')}
      WHERE id = $${paramCount}
      RETURNING *
    `;

    const result = await pool.query(updateQuery, values);

    await logAdminAction(req.admin.id, 'update_customer', 'customer', id, {
      old_email: existingCustomer.rows[0].email,
      new_email: email || existingCustomer.rows[0].email,
      changes: Object.keys(req.body)
    }, req);

    res.json({
      success: true,
      customer: result.rows[0],
      message: 'Client modifié avec succès'
    });

  } catch (err) {
    console.error('❌ Erreur modification client:', err);
    res.status(500).json({
      success: false,
      error: 'Erreur lors de la modification du client'
    });
  }
});

// Supprimer un client (admin) - Attention : supprime aussi ses commandes !
app.delete('/api/admin/customers/:id', authenticateAdmin, async (req, res) => {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const { id } = req.params;
    const { force = false } = req.query;

    // Vérifier que le client existe
    const existingCustomer = await client.query(
      'SELECT * FROM customers WHERE id = $1',
      [id]
    );

    if (existingCustomer.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Client non trouvé'
      });
    }

    const customer = existingCustomer.rows[0];

    // Vérifier s'il y a des commandes liées
    const ordersCheck = await client.query(
      'SELECT COUNT(*) as count FROM orders WHERE customer_id = $1',
      [id]
    );

    const orderCount = parseInt(ordersCheck.rows[0].count);

    if (orderCount > 0 && !force) {
      return res.status(400).json({
        success: false,
        error: `Le client a ${orderCount} commande(s). Utilisez force=true pour forcer la suppression.`,
        order_count: orderCount
      });
    }

    if (force && orderCount > 0) {
      // Supprimer les order_items d'abord
      await client.query(
        'DELETE FROM order_items WHERE order_id IN (SELECT id FROM orders WHERE customer_id = $1)',
        [id]
      );

      // Puis supprimer les commandes
      await client.query(
        'DELETE FROM orders WHERE customer_id = $1',
        [id]
      );
    }

    // Supprimer le client
    await client.query(
      'DELETE FROM customers WHERE id = $1',
      [id]
    );

    await client.query('COMMIT');

    await logAdminAction(req.admin.id, 'delete_customer', 'customer', id, {
      customer_email: customer.email,
      customer_name: `${customer.first_name} ${customer.last_name}`,
      orders_deleted: orderCount,
      forced: force
    }, req);

    res.json({
      success: true,
      message: `Client supprimé avec succès${orderCount > 0 ? ` avec ${orderCount} commande(s)` : ''}`
    });

  } catch (err) {
    await client.query('ROLLBACK');
    console.error('❌ Erreur suppression client:', err);
    res.status(500).json({
      success: false,
      error: 'Erreur lors de la suppression du client'
    });
  } finally {
    client.release();
  }
});

// Statistiques des clients (admin)
app.get('/api/admin/customers/stats', authenticateAdmin, async (req, res) => {
  try {
    const stats = await pool.query(`
      SELECT 
        COUNT(*) as total_customers,
        COUNT(CASE WHEN orders_count > 0 THEN 1 END) as customers_with_orders,
        COUNT(CASE WHEN orders_count = 0 THEN 1 END) as customers_without_orders,
        COALESCE(AVG(CASE WHEN orders_count > 0 THEN total_spent END), 0) as avg_customer_value,
        COALESCE(MAX(total_spent), 0) as highest_customer_value,
        COUNT(CASE WHEN created_at >= CURRENT_DATE - INTERVAL '30 days' THEN 1 END) as new_customers_last_30_days,
        COUNT(CASE WHEN last_order_at >= CURRENT_DATE - INTERVAL '30 days' THEN 1 END) as active_customers_last_30_days
      FROM customers
    `);

    // Top 10 des meilleurs clients
    const topCustomers = await pool.query(`
      SELECT 
        id, email, first_name, last_name, 
        orders_count, total_spent, last_order_at
      FROM customers 
      WHERE orders_count > 0
      ORDER BY total_spent DESC 
      LIMIT 10
    `);

    // Répartition par nombre de commandes
    const orderDistribution = await pool.query(`
      SELECT 
        CASE 
          WHEN orders_count = 0 THEN '0 commandes'
          WHEN orders_count = 1 THEN '1 commande'
          WHEN orders_count BETWEEN 2 AND 5 THEN '2-5 commandes'
          WHEN orders_count BETWEEN 6 AND 10 THEN '6-10 commandes'
          ELSE '10+ commandes'
        END as order_range,
        COUNT(*) as customer_count
      FROM customers
      GROUP BY 
        CASE 
          WHEN orders_count = 0 THEN '0 commandes'
          WHEN orders_count = 1 THEN '1 commande'
          WHEN orders_count BETWEEN 2 AND 5 THEN '2-5 commandes'
          WHEN orders_count BETWEEN 6 AND 10 THEN '6-10 commandes'
          ELSE '10+ commandes'
        END
      ORDER BY MIN(orders_count)
    `);

    await logAdminAction(req.admin.id, 'view_customer_stats', 'customers', null, {
      total_customers: stats.rows[0].total_customers
    }, req);

    res.json({
      success: true,
      stats: stats.rows[0],
      top_customers: topCustomers.rows,
      order_distribution: orderDistribution.rows
    });

  } catch (err) {
    console.error('❌ Erreur statistiques clients:', err);
    res.status(500).json({
      success: false,
      error: 'Erreur lors de la récupération des statistiques'
    });
  }
});

module.exports = { app, pool, authenticateAdmin, logAdminAction };