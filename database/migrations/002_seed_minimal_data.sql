-- 002_seed_minimal_data.sql
-- Minimal but realistic seed data for quick end-to-end testing.
-- Uses deterministic UUIDs for stable references across runs.

BEGIN;

-- Users
INSERT INTO users (id, email, password_hash, full_name, role, phone)
VALUES
  ('11111111-1111-1111-1111-111111111111', 'customer1@example.com', 'demo_password_hash', 'Casey Customer', 'customer', '+15550000001'),
  ('22222222-2222-2222-2222-222222222222', 'owner1@example.com',    'demo_password_hash', 'Riley RestaurantOwner', 'restaurant', '+15550000002'),
  ('33333333-3333-3333-3333-333333333333', 'courier1@example.com',  'demo_password_hash', 'Drew Delivery', 'delivery', '+15550000003'),
  ('99999999-9999-9999-9999-999999999999', 'admin@example.com',     'demo_password_hash', 'Alex Admin', 'admin', '+15550000009')
ON CONFLICT (email) DO NOTHING;

-- Restaurants
INSERT INTO restaurants (
  id, owner_user_id, name, description,
  address_line1, city, state, postal_code,
  latitude, longitude, is_open
)
VALUES
  (
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    '22222222-2222-2222-2222-222222222222',
    'Pasta Palace',
    'Fresh pasta, salads, and Italian comfort food.',
    '123 Noodle St', 'San Francisco', 'CA', '94105',
    37.7890, -122.3942, TRUE
  ),
  (
    'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
    '22222222-2222-2222-2222-222222222222',
    'Sushi Station',
    'Nigiri, rolls, and bento boxes made daily.',
    '456 Wasabi Ave', 'San Francisco', 'CA', '94107',
    37.7765, -122.3947, TRUE
  )
ON CONFLICT DO NOTHING;

-- Menus
INSERT INTO menus (id, restaurant_id, name, is_active)
VALUES
  ('aaaaaaaa-0000-0000-0000-000000000001', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'Main Menu', TRUE),
  ('bbbbbbbb-0000-0000-0000-000000000001', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'Main Menu', TRUE)
ON CONFLICT DO NOTHING;

-- Menu items - Pasta Palace
INSERT INTO menu_items (id, menu_id, name, description, price_cents, currency, is_available)
VALUES
  ('aaaa0000-0000-0000-0000-000000000001', 'aaaaaaaa-0000-0000-0000-000000000001', 'Spaghetti Carbonara', 'Creamy sauce, pancetta, parmesan.', 1599, 'USD', TRUE),
  ('aaaa0000-0000-0000-0000-000000000002', 'aaaaaaaa-0000-0000-0000-000000000001', 'Margherita Flatbread', 'Tomato, mozzarella, basil.', 1299, 'USD', TRUE),
  ('aaaa0000-0000-0000-0000-000000000003', 'aaaaaaaa-0000-0000-0000-000000000001', 'House Salad', 'Mixed greens, lemon vinaigrette.', 799, 'USD', TRUE)
ON CONFLICT DO NOTHING;

-- Menu items - Sushi Station
INSERT INTO menu_items (id, menu_id, name, description, price_cents, currency, is_available)
VALUES
  ('bbbb0000-0000-0000-0000-000000000001', 'bbbbbbbb-0000-0000-0000-000000000001', 'Salmon Nigiri (6pc)', 'Fresh salmon over sushi rice.', 1399, 'USD', TRUE),
  ('bbbb0000-0000-0000-0000-000000000002', 'bbbbbbbb-0000-0000-0000-000000000001', 'California Roll', 'Crab, avocado, cucumber.', 999, 'USD', TRUE),
  ('bbbb0000-0000-0000-0000-000000000003', 'bbbbbbbb-0000-0000-0000-000000000001', 'Chicken Teriyaki Bento', 'Rice, salad, teriyaki chicken.', 1699, 'USD', TRUE)
ON CONFLICT DO NOTHING;

-- Sample order (customer -> Pasta Palace)
INSERT INTO orders (
  id, customer_user_id, restaurant_id, status, currency,
  subtotal_cents, delivery_fee_cents, tax_cents, total_cents,
  delivery_address_line1, delivery_city, delivery_state, delivery_postal_code,
  notes, placed_at
)
VALUES
  (
    'cccccccc-cccc-cccc-cccc-cccccccccccc',
    '11111111-1111-1111-1111-111111111111',
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    'paid',
    'USD',
    2398, 399, 240, 3037,
    '987 Market St', 'San Francisco', 'CA', '94103',
    'Leave at door if no answer.', NOW()
  )
ON CONFLICT DO NOTHING;

-- Order items (2 items)
INSERT INTO order_items (
  id, order_id, menu_item_id, name_snapshot, unit_price_cents_snapshot, quantity, line_total_cents
)
VALUES
  (
    'dddddddd-0000-0000-0000-000000000001',
    'cccccccc-cccc-cccc-cccc-cccccccccccc',
    'aaaa0000-0000-0000-0000-000000000001',
    'Spaghetti Carbonara',
    1599,
    1,
    1599
  ),
  (
    'dddddddd-0000-0000-0000-000000000002',
    'cccccccc-cccc-cccc-cccc-cccccccccccc',
    'aaaa0000-0000-0000-0000-000000000003',
    'House Salad',
    799,
    1,
    799
  )
ON CONFLICT DO NOTHING;

-- Payment record
INSERT INTO payment_records (
  id, order_id, provider, provider_payment_id, status, amount_cents, currency
)
VALUES
  (
    'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee',
    'cccccccc-cccc-cccc-cccc-cccccccccccc',
    'mock',
    'mock_pi_123',
    'succeeded',
    3037,
    'USD'
  )
ON CONFLICT DO NOTHING;

-- Delivery assignment
INSERT INTO delivery_assignments (
  id, order_id, courier_user_id, status, assigned_at
)
VALUES
  (
    'ffffffff-ffff-ffff-ffff-ffffffffffff',
    'cccccccc-cccc-cccc-cccc-cccccccccccc',
    '33333333-3333-3333-3333-333333333333',
    'assigned',
    NOW()
  )
ON CONFLICT DO NOTHING;

-- Tracking events for the order timeline
INSERT INTO tracking_events (id, order_id, event_type, event_message, latitude, longitude, created_at)
VALUES
  ('12121212-1212-1212-1212-121212121212', 'cccccccc-cccc-cccc-cccc-cccccccccccc', 'order_placed',        'Order placed and payment received.', 37.7830, -122.4090, NOW() - INTERVAL '12 minutes'),
  ('13131313-1313-1313-1313-131313131313', 'cccccccc-cccc-cccc-cccc-cccccccccccc', 'restaurant_accepted', 'Restaurant accepted the order.',      37.7890, -122.3942, NOW() - INTERVAL '10 minutes'),
  ('14141414-1414-1414-1414-141414141414', 'cccccccc-cccc-cccc-cccc-cccccccccccc', 'preparing',           'Preparing your food.',                37.7890, -122.3942, NOW() - INTERVAL '8 minutes'),
  ('15151515-1515-1515-1515-151515151515', 'cccccccc-cccc-cccc-cccc-cccccccccccc', 'courier_assigned',    'Courier assigned.',                    37.7840, -122.4070, NOW() - INTERVAL '6 minutes')
ON CONFLICT DO NOTHING;

COMMIT;
