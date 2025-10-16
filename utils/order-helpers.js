// Fonction utilitaire pour générer un numéro de commande unique
function generateOrderNumber() {
  const date = new Date();
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  const timestamp = Date.now().toString().slice(-6); // 6 derniers chiffres du timestamp
  
  return `MKW${year}${month}${day}${timestamp}`;
}

// Fonction pour valider les données d'adresse
function validateAddress(address) {
  const required = ['first_name', 'last_name', 'address1', 'city', 'zip', 'country'];
  
  for (const field of required) {
    if (!address[field] || address[field].trim() === '') {
      return { valid: false, missing: field };
    }
  }
  
  return { valid: true };
}

// Fonction pour calculer les frais de livraison
function calculateShippingCost(shippingMethod, total, country = 'FR') {
  const freeShippingThreshold = 50; // Livraison gratuite à partir de 50€
  
  if (total >= freeShippingThreshold) {
    return 0;
  }
  
  switch (shippingMethod) {
    case 'standard':
      return country === 'FR' ? 5.99 : 9.99;
    case 'express':
      return country === 'FR' ? 12.99 : 19.99;
    case 'premium':
      return country === 'FR' ? 19.99 : 29.99;
    default:
      return 5.99;
  }
}

// Fonction pour valider les items de commande
function validateOrderItems(items) {
  if (!Array.isArray(items) || items.length === 0) {
    return { valid: false, error: 'Aucun article dans la commande' };
  }
  
  for (const item of items) {
    if (!item.variant_id || !item.quantity || item.quantity <= 0) {
      return { valid: false, error: 'Données d\'article invalides' };
    }
    
    if (item.quantity > 100) {
      return { valid: false, error: 'Quantité maximale dépassée (100)' };
    }
  }
  
  return { valid: true };
}

// Fonction pour formater les données de commande pour l'email
function formatOrderForEmail(order, items, customer) {
  return {
    orderNumber: order.order_number,
    customerName: `${customer.first_name} ${customer.last_name}`,
    customerEmail: customer.email,
    orderDate: order.created_at,
    subtotal: order.subtotal,
    tax: order.total_tax,
    shipping: order.shipping_cost,
    total: order.total,
    items: items.map(item => ({
      name: `${item.product_title} - ${item.variant_title}`,
      sku: item.sku,
      quantity: item.quantity,
      price: item.price,
      total: item.total
    })),
    shippingAddress: order.shipping_address,
    billingAddress: order.billing_address
  };
}

module.exports = {
  generateOrderNumber,
  validateAddress,
  calculateShippingCost,
  validateOrderItems,
  formatOrderForEmail
};