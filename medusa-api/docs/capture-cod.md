# Capture paiement à la livraison (COD)

## Vue d'ensemble

Le paiement comptant à la livraison (COD - Cash on Delivery) permet aux clients de payer **après réception** du produit, directement au livreur.

Dans MedusaJS, ce flux est géré via le **manual payment provider**.

---

## Flux complet

### 1. Client passe commande

Le client ajoute des produits au panier et valide sa commande **sans paiement en ligne**.

```
État de la commande :
- payment_status: "awaiting" ou "requires_action"
- fulfillment_status: "not_fulfilled"
```

### 2. Préparation et expédition

Vous préparez la commande et l'expédiez. Le livreur emporte le colis avec instructions de paiement COD.

```bash
# Via l'Admin Medusa, marquer comme expédiée :
POST /admin/orders/{order_id}/fulfillment
{
  "items": [...],
  "no_notification": false
}
```

### 3. Livraison et encaissement physique

Le livreur remet le colis au client et **encaisse le paiement** (espèces ou CB portable).

### 4. Capture du paiement dans Medusa

Une fois le paiement physique reçu, vous devez le **capturer dans l'admin** pour finaliser la commande.

---

## Comment capturer un paiement COD

### Option 1 : Via l'Admin UI

1. Connectez-vous à **Medusa Admin** : `http://localhost:7001`
2. Allez dans **Orders** → Sélectionnez la commande
3. Dans la section **Payment**, cliquez sur **Capture Payment**
4. Confirmez

✅ Le `payment_status` passe à **"captured"**

### Option 2 : Via l'API (manuel)

#### Étape 1 : Récupérer l'ID du paiement

```bash
GET /admin/orders/{order_id}
```

Réponse :
```json
{
  "order": {
    "id": "order_123",
    "payments": [
      {
        "id": "pay_456",
        "amount": 39000,
        "captured_at": null
      }
    ]
  }
}
```

#### Étape 2 : Capturer le paiement

```bash
POST /admin/payments/{payment_id}/capture
Headers:
  Authorization: Bearer {ADMIN_TOKEN}
  Content-Type: application/json
```

Réponse :
```json
{
  "payment": {
    "id": "pay_456",
    "captured_at": "2025-10-05T14:30:00Z"
  }
}
```

---

## Script automatisé (optionnel)

Créez un script pour capturer les paiements en masse :

```typescript
// medusa-api/src/scripts/capture-payments.ts
import Medusa from "@medusajs/medusa-js"

const medusa = new Medusa({ baseUrl: "http://localhost:9000" })

async function captureOrderPayment(orderId: string) {
  const auth = await medusa.admin.auth.getToken({
    email: "admin@menow.fr",
    password: "supersecret"
  })

  const { order } = await medusa.admin.orders.retrieve(orderId)
  const payment = order.payments.find(p => !p.captured_at)

  if (payment) {
    await medusa.admin.payments.capturePayment(payment.id)
    console.log(`✅ Paiement capturé pour commande ${orderId}`)
  }
}

captureOrderPayment("order_123")
```

---

## Bonnes pratiques

1. **Suivi transporteur** : Utilisez un service avec preuve de livraison
2. **Délai de capture** : Capturez le paiement **le jour même** de la livraison
3. **Communication client** : Envoyez un email de confirmation après capture
4. **Rapprochement comptable** : Vérifiez que montant physique = montant commande

---

## FAQ

### Que se passe-t-il si le client refuse le colis ?

Annulez la commande via l'admin :
```bash
POST /admin/orders/{order_id}/cancel
```

### Peut-on capturer partiellement ?

Non, MedusaJS capture le montant total. Pour des retours partiels, utilisez le système de **refunds**.

### Différence entre "authorize" et "capture" ?

- **Authorize** : Réserve les fonds (carte bancaire)
- **Capture** : Encaisse réellement les fonds

Avec COD, il n'y a pas d'autorisation préalable, donc on capture directement.

---

## Support

Pour toute question : contact@menow.fr
