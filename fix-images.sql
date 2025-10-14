-- Script SQL pour corriger les images 404
-- Remplacer les URLs Unsplash par des images locales

UPDATE product 
SET thumbnail = '/products/luxury_fashion_jacke_28fde759.jpg'
WHERE handle = 'blouson-cuir-premium';

UPDATE product 
SET thumbnail = '/products/luxury_fashion_jacke_45c6de81.jpg'
WHERE handle = 'jean-denim-selvage';

UPDATE product 
SET thumbnail = '/products/premium_fashion_coll_0e2672aa.jpg'
WHERE handle = 'chemise-lin-naturel';

UPDATE product 
SET thumbnail = '/products/premium_fashion_coll_55d86770.jpg'
WHERE handle = 'tshirt-coton-bio';

-- Mettre à jour aussi les images dans la table image si elle existe
UPDATE image 
SET url = '/products/luxury_fashion_jacke_28fde759.jpg'
WHERE url LIKE '%unsplash%' 
AND EXISTS (SELECT 1 FROM product WHERE product.id = image.metadata::json->>'product_id' AND product.handle = 'blouson-cuir-premium');

UPDATE image 
SET url = '/products/luxury_fashion_jacke_45c6de81.jpg'
WHERE url LIKE '%unsplash%' 
AND EXISTS (SELECT 1 FROM product WHERE product.id = image.metadata::json->>'product_id' AND product.handle = 'jean-denim-selvage');

UPDATE image 
SET url = '/products/premium_fashion_coll_0e2672aa.jpg'
WHERE url LIKE '%unsplash%' 
AND EXISTS (SELECT 1 FROM product WHERE product.id = image.metadata::json->>'product_id' AND product.handle = 'chemise-lin-naturel');

UPDATE image 
SET url = '/products/premium_fashion_coll_55d86770.jpg'
WHERE url LIKE '%unsplash%' 
AND EXISTS (SELECT 1 FROM product WHERE product.id = image.metadata::json->>'product_id' AND product.handle = 'tshirt-coton-bio');

-- Vérifier les changements
SELECT handle, title, thumbnail FROM product WHERE handle IN ('blouson-cuir-premium', 'jean-denim-selvage', 'chemise-lin-naturel', 'tshirt-coton-bio');