--
-- PostgreSQL database dump
--

\restrict fRVRpi7JFRyexNG2htE33nRBChSW7mqgl9B9wdzqvMC4Q7iRJJG5PFtbxdCwVDl

-- Dumped from database version 16.11 (Ubuntu 16.11-0ubuntu0.24.04.1)
-- Dumped by pg_dump version 16.11 (Ubuntu 16.11-0ubuntu0.24.04.1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

DROP DATABASE IF EXISTS myapp;
--
-- Name: myapp; Type: DATABASE; Schema: -; Owner: postgres
--

CREATE DATABASE myapp WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'en_US.UTF-8';


ALTER DATABASE myapp OWNER TO postgres;

\unrestrict fRVRpi7JFRyexNG2htE33nRBChSW7mqgl9B9wdzqvMC4Q7iRJJG5PFtbxdCwVDl
\connect myapp
\restrict fRVRpi7JFRyexNG2htE33nRBChSW7mqgl9B9wdzqvMC4Q7iRJJG5PFtbxdCwVDl

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: citext; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS citext WITH SCHEMA public;


--
-- Name: EXTENSION citext; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION citext IS 'data type for case-insensitive character strings';


--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: delivery_status; Type: TYPE; Schema: public; Owner: appuser
--

CREATE TYPE public.delivery_status AS ENUM (
    'unassigned',
    'assigned',
    'en_route_to_restaurant',
    'picked_up',
    'en_route_to_customer',
    'delivered',
    'cancelled'
);


ALTER TYPE public.delivery_status OWNER TO appuser;

--
-- Name: order_status; Type: TYPE; Schema: public; Owner: appuser
--

CREATE TYPE public.order_status AS ENUM (
    'pending_payment',
    'paid',
    'accepted',
    'preparing',
    'ready_for_pickup',
    'picked_up',
    'delivered',
    'cancelled',
    'refunded'
);


ALTER TYPE public.order_status OWNER TO appuser;

--
-- Name: payment_status; Type: TYPE; Schema: public; Owner: appuser
--

CREATE TYPE public.payment_status AS ENUM (
    'requires_payment',
    'processing',
    'succeeded',
    'failed',
    'refunded'
);


ALTER TYPE public.payment_status OWNER TO appuser;

--
-- Name: user_role; Type: TYPE; Schema: public; Owner: appuser
--

CREATE TYPE public.user_role AS ENUM (
    'customer',
    'restaurant',
    'delivery',
    'admin'
);


ALTER TYPE public.user_role OWNER TO appuser;

--
-- Name: set_updated_at(); Type: FUNCTION; Schema: public; Owner: appuser
--

CREATE FUNCTION public.set_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;


ALTER FUNCTION public.set_updated_at() OWNER TO appuser;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: delivery_assignments; Type: TABLE; Schema: public; Owner: appuser
--

CREATE TABLE public.delivery_assignments (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    order_id uuid NOT NULL,
    courier_user_id uuid,
    status public.delivery_status DEFAULT 'unassigned'::public.delivery_status NOT NULL,
    assigned_at timestamp with time zone,
    picked_up_at timestamp with time zone,
    delivered_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.delivery_assignments OWNER TO appuser;

--
-- Name: menu_items; Type: TABLE; Schema: public; Owner: appuser
--

CREATE TABLE public.menu_items (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    menu_id uuid NOT NULL,
    name text NOT NULL,
    description text,
    price_cents integer NOT NULL,
    currency text DEFAULT 'USD'::text NOT NULL,
    is_available boolean DEFAULT true NOT NULL,
    image_url text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT menu_items_price_cents_check CHECK ((price_cents >= 0))
);


ALTER TABLE public.menu_items OWNER TO appuser;

--
-- Name: menus; Type: TABLE; Schema: public; Owner: appuser
--

CREATE TABLE public.menus (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    restaurant_id uuid NOT NULL,
    name text NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.menus OWNER TO appuser;

--
-- Name: order_items; Type: TABLE; Schema: public; Owner: appuser
--

CREATE TABLE public.order_items (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    order_id uuid NOT NULL,
    menu_item_id uuid NOT NULL,
    name_snapshot text NOT NULL,
    unit_price_cents_snapshot integer NOT NULL,
    quantity integer NOT NULL,
    line_total_cents integer NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT order_items_line_total_cents_check CHECK ((line_total_cents >= 0)),
    CONSTRAINT order_items_quantity_check CHECK ((quantity > 0)),
    CONSTRAINT order_items_unit_price_cents_snapshot_check CHECK ((unit_price_cents_snapshot >= 0))
);


ALTER TABLE public.order_items OWNER TO appuser;

--
-- Name: orders; Type: TABLE; Schema: public; Owner: appuser
--

CREATE TABLE public.orders (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    customer_user_id uuid NOT NULL,
    restaurant_id uuid NOT NULL,
    status public.order_status DEFAULT 'pending_payment'::public.order_status NOT NULL,
    currency text DEFAULT 'USD'::text NOT NULL,
    subtotal_cents integer DEFAULT 0 NOT NULL,
    delivery_fee_cents integer DEFAULT 0 NOT NULL,
    tax_cents integer DEFAULT 0 NOT NULL,
    total_cents integer DEFAULT 0 NOT NULL,
    delivery_address_line1 text NOT NULL,
    delivery_address_line2 text,
    delivery_city text NOT NULL,
    delivery_state text,
    delivery_postal_code text,
    notes text,
    placed_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT orders_delivery_fee_cents_check CHECK ((delivery_fee_cents >= 0)),
    CONSTRAINT orders_subtotal_cents_check CHECK ((subtotal_cents >= 0)),
    CONSTRAINT orders_tax_cents_check CHECK ((tax_cents >= 0)),
    CONSTRAINT orders_total_cents_check CHECK ((total_cents >= 0))
);


ALTER TABLE public.orders OWNER TO appuser;

--
-- Name: payment_records; Type: TABLE; Schema: public; Owner: appuser
--

CREATE TABLE public.payment_records (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    order_id uuid NOT NULL,
    provider text DEFAULT 'mock'::text NOT NULL,
    provider_payment_id text,
    status public.payment_status DEFAULT 'requires_payment'::public.payment_status NOT NULL,
    amount_cents integer NOT NULL,
    currency text DEFAULT 'USD'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT payment_records_amount_cents_check CHECK ((amount_cents >= 0))
);


ALTER TABLE public.payment_records OWNER TO appuser;

--
-- Name: restaurants; Type: TABLE; Schema: public; Owner: appuser
--

CREATE TABLE public.restaurants (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    owner_user_id uuid NOT NULL,
    name text NOT NULL,
    description text,
    address_line1 text,
    address_line2 text,
    city text,
    state text,
    postal_code text,
    latitude double precision,
    longitude double precision,
    is_open boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.restaurants OWNER TO appuser;

--
-- Name: tracking_events; Type: TABLE; Schema: public; Owner: appuser
--

CREATE TABLE public.tracking_events (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    order_id uuid NOT NULL,
    event_type text NOT NULL,
    event_message text,
    latitude double precision,
    longitude double precision,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.tracking_events OWNER TO appuser;

--
-- Name: users; Type: TABLE; Schema: public; Owner: appuser
--

CREATE TABLE public.users (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    email public.citext NOT NULL,
    password_hash text NOT NULL,
    full_name text NOT NULL,
    role public.user_role DEFAULT 'customer'::public.user_role NOT NULL,
    phone text,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.users OWNER TO appuser;

--
-- Data for Name: delivery_assignments; Type: TABLE DATA; Schema: public; Owner: appuser
--

COPY public.delivery_assignments (id, order_id, courier_user_id, status, assigned_at, picked_up_at, delivered_at, created_at, updated_at) FROM stdin;
ffffffff-ffff-ffff-ffff-ffffffffffff	cccccccc-cccc-cccc-cccc-cccccccccccc	33333333-3333-3333-3333-333333333333	assigned	2026-01-06 07:22:47.100255+00	\N	\N	2026-01-06 07:22:47.100255+00	2026-01-06 07:22:47.100255+00
\.


--
-- Data for Name: menu_items; Type: TABLE DATA; Schema: public; Owner: appuser
--

COPY public.menu_items (id, menu_id, name, description, price_cents, currency, is_available, image_url, created_at, updated_at) FROM stdin;
aaaa0000-0000-0000-0000-000000000001	aaaaaaaa-0000-0000-0000-000000000001	Spaghetti Carbonara	Creamy sauce, pancetta, parmesan.	1599	USD	t	\N	2026-01-06 07:22:47.100255+00	2026-01-06 07:22:47.100255+00
aaaa0000-0000-0000-0000-000000000002	aaaaaaaa-0000-0000-0000-000000000001	Margherita Flatbread	Tomato, mozzarella, basil.	1299	USD	t	\N	2026-01-06 07:22:47.100255+00	2026-01-06 07:22:47.100255+00
aaaa0000-0000-0000-0000-000000000003	aaaaaaaa-0000-0000-0000-000000000001	House Salad	Mixed greens, lemon vinaigrette.	799	USD	t	\N	2026-01-06 07:22:47.100255+00	2026-01-06 07:22:47.100255+00
bbbb0000-0000-0000-0000-000000000001	bbbbbbbb-0000-0000-0000-000000000001	Salmon Nigiri (6pc)	Fresh salmon over sushi rice.	1399	USD	t	\N	2026-01-06 07:22:47.100255+00	2026-01-06 07:22:47.100255+00
bbbb0000-0000-0000-0000-000000000002	bbbbbbbb-0000-0000-0000-000000000001	California Roll	Crab, avocado, cucumber.	999	USD	t	\N	2026-01-06 07:22:47.100255+00	2026-01-06 07:22:47.100255+00
bbbb0000-0000-0000-0000-000000000003	bbbbbbbb-0000-0000-0000-000000000001	Chicken Teriyaki Bento	Rice, salad, teriyaki chicken.	1699	USD	t	\N	2026-01-06 07:22:47.100255+00	2026-01-06 07:22:47.100255+00
\.


--
-- Data for Name: menus; Type: TABLE DATA; Schema: public; Owner: appuser
--

COPY public.menus (id, restaurant_id, name, is_active, created_at, updated_at) FROM stdin;
aaaaaaaa-0000-0000-0000-000000000001	aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa	Main Menu	t	2026-01-06 07:22:47.100255+00	2026-01-06 07:22:47.100255+00
bbbbbbbb-0000-0000-0000-000000000001	bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb	Main Menu	t	2026-01-06 07:22:47.100255+00	2026-01-06 07:22:47.100255+00
\.


--
-- Data for Name: order_items; Type: TABLE DATA; Schema: public; Owner: appuser
--

COPY public.order_items (id, order_id, menu_item_id, name_snapshot, unit_price_cents_snapshot, quantity, line_total_cents, created_at) FROM stdin;
dddddddd-0000-0000-0000-000000000001	cccccccc-cccc-cccc-cccc-cccccccccccc	aaaa0000-0000-0000-0000-000000000001	Spaghetti Carbonara	1599	1	1599	2026-01-06 07:22:47.100255+00
dddddddd-0000-0000-0000-000000000002	cccccccc-cccc-cccc-cccc-cccccccccccc	aaaa0000-0000-0000-0000-000000000003	House Salad	799	1	799	2026-01-06 07:22:47.100255+00
\.


--
-- Data for Name: orders; Type: TABLE DATA; Schema: public; Owner: appuser
--

COPY public.orders (id, customer_user_id, restaurant_id, status, currency, subtotal_cents, delivery_fee_cents, tax_cents, total_cents, delivery_address_line1, delivery_address_line2, delivery_city, delivery_state, delivery_postal_code, notes, placed_at, created_at, updated_at) FROM stdin;
cccccccc-cccc-cccc-cccc-cccccccccccc	11111111-1111-1111-1111-111111111111	aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa	paid	USD	2398	399	240	3037	987 Market St	\N	San Francisco	CA	94103	Leave at door if no answer.	2026-01-06 07:22:47.100255+00	2026-01-06 07:22:47.100255+00	2026-01-06 07:22:47.100255+00
\.


--
-- Data for Name: payment_records; Type: TABLE DATA; Schema: public; Owner: appuser
--

COPY public.payment_records (id, order_id, provider, provider_payment_id, status, amount_cents, currency, created_at, updated_at) FROM stdin;
eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee	cccccccc-cccc-cccc-cccc-cccccccccccc	mock	mock_pi_123	succeeded	3037	USD	2026-01-06 07:22:47.100255+00	2026-01-06 07:22:47.100255+00
\.


--
-- Data for Name: restaurants; Type: TABLE DATA; Schema: public; Owner: appuser
--

COPY public.restaurants (id, owner_user_id, name, description, address_line1, address_line2, city, state, postal_code, latitude, longitude, is_open, created_at, updated_at) FROM stdin;
aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa	22222222-2222-2222-2222-222222222222	Pasta Palace	Fresh pasta, salads, and Italian comfort food.	123 Noodle St	\N	San Francisco	CA	94105	37.789	-122.3942	t	2026-01-06 07:22:47.100255+00	2026-01-06 07:22:47.100255+00
bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb	22222222-2222-2222-2222-222222222222	Sushi Station	Nigiri, rolls, and bento boxes made daily.	456 Wasabi Ave	\N	San Francisco	CA	94107	37.7765	-122.3947	t	2026-01-06 07:22:47.100255+00	2026-01-06 07:22:47.100255+00
\.


--
-- Data for Name: tracking_events; Type: TABLE DATA; Schema: public; Owner: appuser
--

COPY public.tracking_events (id, order_id, event_type, event_message, latitude, longitude, created_at) FROM stdin;
12121212-1212-1212-1212-121212121212	cccccccc-cccc-cccc-cccc-cccccccccccc	order_placed	Order placed and payment received.	37.783	-122.409	2026-01-06 07:10:47.100255+00
13131313-1313-1313-1313-131313131313	cccccccc-cccc-cccc-cccc-cccccccccccc	restaurant_accepted	Restaurant accepted the order.	37.789	-122.3942	2026-01-06 07:12:47.100255+00
14141414-1414-1414-1414-141414141414	cccccccc-cccc-cccc-cccc-cccccccccccc	preparing	Preparing your food.	37.789	-122.3942	2026-01-06 07:14:47.100255+00
15151515-1515-1515-1515-151515151515	cccccccc-cccc-cccc-cccc-cccccccccccc	courier_assigned	Courier assigned.	37.784	-122.407	2026-01-06 07:16:47.100255+00
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: appuser
--

COPY public.users (id, email, password_hash, full_name, role, phone, is_active, created_at, updated_at) FROM stdin;
11111111-1111-1111-1111-111111111111	customer1@example.com	demo_password_hash	Casey Customer	customer	+15550000001	t	2026-01-06 07:22:47.100255+00	2026-01-06 07:22:47.100255+00
22222222-2222-2222-2222-222222222222	owner1@example.com	demo_password_hash	Riley RestaurantOwner	restaurant	+15550000002	t	2026-01-06 07:22:47.100255+00	2026-01-06 07:22:47.100255+00
33333333-3333-3333-3333-333333333333	courier1@example.com	demo_password_hash	Drew Delivery	delivery	+15550000003	t	2026-01-06 07:22:47.100255+00	2026-01-06 07:22:47.100255+00
99999999-9999-9999-9999-999999999999	admin@example.com	demo_password_hash	Alex Admin	admin	+15550000009	t	2026-01-06 07:22:47.100255+00	2026-01-06 07:22:47.100255+00
\.


--
-- Name: delivery_assignments delivery_assignments_order_id_key; Type: CONSTRAINT; Schema: public; Owner: appuser
--

ALTER TABLE ONLY public.delivery_assignments
    ADD CONSTRAINT delivery_assignments_order_id_key UNIQUE (order_id);


--
-- Name: delivery_assignments delivery_assignments_pkey; Type: CONSTRAINT; Schema: public; Owner: appuser
--

ALTER TABLE ONLY public.delivery_assignments
    ADD CONSTRAINT delivery_assignments_pkey PRIMARY KEY (id);


--
-- Name: menu_items menu_items_pkey; Type: CONSTRAINT; Schema: public; Owner: appuser
--

ALTER TABLE ONLY public.menu_items
    ADD CONSTRAINT menu_items_pkey PRIMARY KEY (id);


--
-- Name: menus menus_pkey; Type: CONSTRAINT; Schema: public; Owner: appuser
--

ALTER TABLE ONLY public.menus
    ADD CONSTRAINT menus_pkey PRIMARY KEY (id);


--
-- Name: menus menus_restaurant_id_name_key; Type: CONSTRAINT; Schema: public; Owner: appuser
--

ALTER TABLE ONLY public.menus
    ADD CONSTRAINT menus_restaurant_id_name_key UNIQUE (restaurant_id, name);


--
-- Name: order_items order_items_pkey; Type: CONSTRAINT; Schema: public; Owner: appuser
--

ALTER TABLE ONLY public.order_items
    ADD CONSTRAINT order_items_pkey PRIMARY KEY (id);


--
-- Name: orders orders_pkey; Type: CONSTRAINT; Schema: public; Owner: appuser
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT orders_pkey PRIMARY KEY (id);


--
-- Name: payment_records payment_records_pkey; Type: CONSTRAINT; Schema: public; Owner: appuser
--

ALTER TABLE ONLY public.payment_records
    ADD CONSTRAINT payment_records_pkey PRIMARY KEY (id);


--
-- Name: restaurants restaurants_pkey; Type: CONSTRAINT; Schema: public; Owner: appuser
--

ALTER TABLE ONLY public.restaurants
    ADD CONSTRAINT restaurants_pkey PRIMARY KEY (id);


--
-- Name: tracking_events tracking_events_pkey; Type: CONSTRAINT; Schema: public; Owner: appuser
--

ALTER TABLE ONLY public.tracking_events
    ADD CONSTRAINT tracking_events_pkey PRIMARY KEY (id);


--
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: appuser
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: appuser
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: idx_delivery_assignments_courier; Type: INDEX; Schema: public; Owner: appuser
--

CREATE INDEX idx_delivery_assignments_courier ON public.delivery_assignments USING btree (courier_user_id);


--
-- Name: idx_delivery_assignments_status; Type: INDEX; Schema: public; Owner: appuser
--

CREATE INDEX idx_delivery_assignments_status ON public.delivery_assignments USING btree (status);


--
-- Name: idx_menu_items_available; Type: INDEX; Schema: public; Owner: appuser
--

CREATE INDEX idx_menu_items_available ON public.menu_items USING btree (is_available);


--
-- Name: idx_menu_items_menu; Type: INDEX; Schema: public; Owner: appuser
--

CREATE INDEX idx_menu_items_menu ON public.menu_items USING btree (menu_id);


--
-- Name: idx_menus_restaurant; Type: INDEX; Schema: public; Owner: appuser
--

CREATE INDEX idx_menus_restaurant ON public.menus USING btree (restaurant_id);


--
-- Name: idx_order_items_order; Type: INDEX; Schema: public; Owner: appuser
--

CREATE INDEX idx_order_items_order ON public.order_items USING btree (order_id);


--
-- Name: idx_orders_created_at; Type: INDEX; Schema: public; Owner: appuser
--

CREATE INDEX idx_orders_created_at ON public.orders USING btree (created_at);


--
-- Name: idx_orders_customer; Type: INDEX; Schema: public; Owner: appuser
--

CREATE INDEX idx_orders_customer ON public.orders USING btree (customer_user_id);


--
-- Name: idx_orders_restaurant; Type: INDEX; Schema: public; Owner: appuser
--

CREATE INDEX idx_orders_restaurant ON public.orders USING btree (restaurant_id);


--
-- Name: idx_orders_status; Type: INDEX; Schema: public; Owner: appuser
--

CREATE INDEX idx_orders_status ON public.orders USING btree (status);


--
-- Name: idx_payment_records_order; Type: INDEX; Schema: public; Owner: appuser
--

CREATE INDEX idx_payment_records_order ON public.payment_records USING btree (order_id);


--
-- Name: idx_payment_records_status; Type: INDEX; Schema: public; Owner: appuser
--

CREATE INDEX idx_payment_records_status ON public.payment_records USING btree (status);


--
-- Name: idx_restaurants_city; Type: INDEX; Schema: public; Owner: appuser
--

CREATE INDEX idx_restaurants_city ON public.restaurants USING btree (city);


--
-- Name: idx_restaurants_owner; Type: INDEX; Schema: public; Owner: appuser
--

CREATE INDEX idx_restaurants_owner ON public.restaurants USING btree (owner_user_id);


--
-- Name: idx_tracking_events_created_at; Type: INDEX; Schema: public; Owner: appuser
--

CREATE INDEX idx_tracking_events_created_at ON public.tracking_events USING btree (created_at);


--
-- Name: idx_tracking_events_order; Type: INDEX; Schema: public; Owner: appuser
--

CREATE INDEX idx_tracking_events_order ON public.tracking_events USING btree (order_id);


--
-- Name: idx_users_role; Type: INDEX; Schema: public; Owner: appuser
--

CREATE INDEX idx_users_role ON public.users USING btree (role);


--
-- Name: delivery_assignments trg_delivery_assignments_set_updated_at; Type: TRIGGER; Schema: public; Owner: appuser
--

CREATE TRIGGER trg_delivery_assignments_set_updated_at BEFORE UPDATE ON public.delivery_assignments FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- Name: menu_items trg_menu_items_set_updated_at; Type: TRIGGER; Schema: public; Owner: appuser
--

CREATE TRIGGER trg_menu_items_set_updated_at BEFORE UPDATE ON public.menu_items FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- Name: menus trg_menus_set_updated_at; Type: TRIGGER; Schema: public; Owner: appuser
--

CREATE TRIGGER trg_menus_set_updated_at BEFORE UPDATE ON public.menus FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- Name: orders trg_orders_set_updated_at; Type: TRIGGER; Schema: public; Owner: appuser
--

CREATE TRIGGER trg_orders_set_updated_at BEFORE UPDATE ON public.orders FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- Name: payment_records trg_payment_records_set_updated_at; Type: TRIGGER; Schema: public; Owner: appuser
--

CREATE TRIGGER trg_payment_records_set_updated_at BEFORE UPDATE ON public.payment_records FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- Name: restaurants trg_restaurants_set_updated_at; Type: TRIGGER; Schema: public; Owner: appuser
--

CREATE TRIGGER trg_restaurants_set_updated_at BEFORE UPDATE ON public.restaurants FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- Name: users trg_users_set_updated_at; Type: TRIGGER; Schema: public; Owner: appuser
--

CREATE TRIGGER trg_users_set_updated_at BEFORE UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- Name: delivery_assignments delivery_assignments_courier_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: appuser
--

ALTER TABLE ONLY public.delivery_assignments
    ADD CONSTRAINT delivery_assignments_courier_user_id_fkey FOREIGN KEY (courier_user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: delivery_assignments delivery_assignments_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: appuser
--

ALTER TABLE ONLY public.delivery_assignments
    ADD CONSTRAINT delivery_assignments_order_id_fkey FOREIGN KEY (order_id) REFERENCES public.orders(id) ON DELETE CASCADE;


--
-- Name: menu_items menu_items_menu_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: appuser
--

ALTER TABLE ONLY public.menu_items
    ADD CONSTRAINT menu_items_menu_id_fkey FOREIGN KEY (menu_id) REFERENCES public.menus(id) ON DELETE CASCADE;


--
-- Name: menus menus_restaurant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: appuser
--

ALTER TABLE ONLY public.menus
    ADD CONSTRAINT menus_restaurant_id_fkey FOREIGN KEY (restaurant_id) REFERENCES public.restaurants(id) ON DELETE CASCADE;


--
-- Name: order_items order_items_menu_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: appuser
--

ALTER TABLE ONLY public.order_items
    ADD CONSTRAINT order_items_menu_item_id_fkey FOREIGN KEY (menu_item_id) REFERENCES public.menu_items(id) ON DELETE RESTRICT;


--
-- Name: order_items order_items_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: appuser
--

ALTER TABLE ONLY public.order_items
    ADD CONSTRAINT order_items_order_id_fkey FOREIGN KEY (order_id) REFERENCES public.orders(id) ON DELETE CASCADE;


--
-- Name: orders orders_customer_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: appuser
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT orders_customer_user_id_fkey FOREIGN KEY (customer_user_id) REFERENCES public.users(id) ON DELETE RESTRICT;


--
-- Name: orders orders_restaurant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: appuser
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT orders_restaurant_id_fkey FOREIGN KEY (restaurant_id) REFERENCES public.restaurants(id) ON DELETE RESTRICT;


--
-- Name: payment_records payment_records_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: appuser
--

ALTER TABLE ONLY public.payment_records
    ADD CONSTRAINT payment_records_order_id_fkey FOREIGN KEY (order_id) REFERENCES public.orders(id) ON DELETE CASCADE;


--
-- Name: restaurants restaurants_owner_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: appuser
--

ALTER TABLE ONLY public.restaurants
    ADD CONSTRAINT restaurants_owner_user_id_fkey FOREIGN KEY (owner_user_id) REFERENCES public.users(id) ON DELETE RESTRICT;


--
-- Name: tracking_events tracking_events_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: appuser
--

ALTER TABLE ONLY public.tracking_events
    ADD CONSTRAINT tracking_events_order_id_fkey FOREIGN KEY (order_id) REFERENCES public.orders(id) ON DELETE CASCADE;


--
-- Name: DATABASE myapp; Type: ACL; Schema: -; Owner: postgres
--

GRANT ALL ON DATABASE myapp TO appuser;


--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: pg_database_owner
--

GRANT ALL ON SCHEMA public TO appuser;


--
-- Name: FUNCTION citextin(cstring); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.citextin(cstring) TO appuser;


--
-- Name: FUNCTION citextout(public.citext); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.citextout(public.citext) TO appuser;


--
-- Name: FUNCTION citextrecv(internal); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.citextrecv(internal) TO appuser;


--
-- Name: FUNCTION citextsend(public.citext); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.citextsend(public.citext) TO appuser;


--
-- Name: TYPE citext; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TYPE public.citext TO appuser;


--
-- Name: FUNCTION citext(boolean); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.citext(boolean) TO appuser;


--
-- Name: FUNCTION citext(character); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.citext(character) TO appuser;


--
-- Name: FUNCTION citext(inet); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.citext(inet) TO appuser;


--
-- Name: FUNCTION armor(bytea); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.armor(bytea) TO appuser;


--
-- Name: FUNCTION armor(bytea, text[], text[]); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.armor(bytea, text[], text[]) TO appuser;


--
-- Name: FUNCTION citext_cmp(public.citext, public.citext); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.citext_cmp(public.citext, public.citext) TO appuser;


--
-- Name: FUNCTION citext_eq(public.citext, public.citext); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.citext_eq(public.citext, public.citext) TO appuser;


--
-- Name: FUNCTION citext_ge(public.citext, public.citext); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.citext_ge(public.citext, public.citext) TO appuser;


--
-- Name: FUNCTION citext_gt(public.citext, public.citext); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.citext_gt(public.citext, public.citext) TO appuser;


--
-- Name: FUNCTION citext_hash(public.citext); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.citext_hash(public.citext) TO appuser;


--
-- Name: FUNCTION citext_hash_extended(public.citext, bigint); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.citext_hash_extended(public.citext, bigint) TO appuser;


--
-- Name: FUNCTION citext_larger(public.citext, public.citext); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.citext_larger(public.citext, public.citext) TO appuser;


--
-- Name: FUNCTION citext_le(public.citext, public.citext); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.citext_le(public.citext, public.citext) TO appuser;


--
-- Name: FUNCTION citext_lt(public.citext, public.citext); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.citext_lt(public.citext, public.citext) TO appuser;


--
-- Name: FUNCTION citext_ne(public.citext, public.citext); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.citext_ne(public.citext, public.citext) TO appuser;


--
-- Name: FUNCTION citext_pattern_cmp(public.citext, public.citext); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.citext_pattern_cmp(public.citext, public.citext) TO appuser;


--
-- Name: FUNCTION citext_pattern_ge(public.citext, public.citext); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.citext_pattern_ge(public.citext, public.citext) TO appuser;


--
-- Name: FUNCTION citext_pattern_gt(public.citext, public.citext); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.citext_pattern_gt(public.citext, public.citext) TO appuser;


--
-- Name: FUNCTION citext_pattern_le(public.citext, public.citext); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.citext_pattern_le(public.citext, public.citext) TO appuser;


--
-- Name: FUNCTION citext_pattern_lt(public.citext, public.citext); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.citext_pattern_lt(public.citext, public.citext) TO appuser;


--
-- Name: FUNCTION citext_smaller(public.citext, public.citext); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.citext_smaller(public.citext, public.citext) TO appuser;


--
-- Name: FUNCTION crypt(text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.crypt(text, text) TO appuser;


--
-- Name: FUNCTION dearmor(text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.dearmor(text) TO appuser;


--
-- Name: FUNCTION decrypt(bytea, bytea, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.decrypt(bytea, bytea, text) TO appuser;


--
-- Name: FUNCTION decrypt_iv(bytea, bytea, bytea, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.decrypt_iv(bytea, bytea, bytea, text) TO appuser;


--
-- Name: FUNCTION digest(bytea, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.digest(bytea, text) TO appuser;


--
-- Name: FUNCTION digest(text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.digest(text, text) TO appuser;


--
-- Name: FUNCTION encrypt(bytea, bytea, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.encrypt(bytea, bytea, text) TO appuser;


--
-- Name: FUNCTION encrypt_iv(bytea, bytea, bytea, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.encrypt_iv(bytea, bytea, bytea, text) TO appuser;


--
-- Name: FUNCTION gen_random_bytes(integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.gen_random_bytes(integer) TO appuser;


--
-- Name: FUNCTION gen_random_uuid(); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.gen_random_uuid() TO appuser;


--
-- Name: FUNCTION gen_salt(text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.gen_salt(text) TO appuser;


--
-- Name: FUNCTION gen_salt(text, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.gen_salt(text, integer) TO appuser;


--
-- Name: FUNCTION hmac(bytea, bytea, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.hmac(bytea, bytea, text) TO appuser;


--
-- Name: FUNCTION hmac(text, text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.hmac(text, text, text) TO appuser;


--
-- Name: FUNCTION pgp_armor_headers(text, OUT key text, OUT value text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_armor_headers(text, OUT key text, OUT value text) TO appuser;


--
-- Name: FUNCTION pgp_key_id(bytea); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_key_id(bytea) TO appuser;


--
-- Name: FUNCTION pgp_pub_decrypt(bytea, bytea); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_pub_decrypt(bytea, bytea) TO appuser;


--
-- Name: FUNCTION pgp_pub_decrypt(bytea, bytea, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_pub_decrypt(bytea, bytea, text) TO appuser;


--
-- Name: FUNCTION pgp_pub_decrypt(bytea, bytea, text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_pub_decrypt(bytea, bytea, text, text) TO appuser;


--
-- Name: FUNCTION pgp_pub_decrypt_bytea(bytea, bytea); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_pub_decrypt_bytea(bytea, bytea) TO appuser;


--
-- Name: FUNCTION pgp_pub_decrypt_bytea(bytea, bytea, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_pub_decrypt_bytea(bytea, bytea, text) TO appuser;


--
-- Name: FUNCTION pgp_pub_decrypt_bytea(bytea, bytea, text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_pub_decrypt_bytea(bytea, bytea, text, text) TO appuser;


--
-- Name: FUNCTION pgp_pub_encrypt(text, bytea); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_pub_encrypt(text, bytea) TO appuser;


--
-- Name: FUNCTION pgp_pub_encrypt(text, bytea, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_pub_encrypt(text, bytea, text) TO appuser;


--
-- Name: FUNCTION pgp_pub_encrypt_bytea(bytea, bytea); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_pub_encrypt_bytea(bytea, bytea) TO appuser;


--
-- Name: FUNCTION pgp_pub_encrypt_bytea(bytea, bytea, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_pub_encrypt_bytea(bytea, bytea, text) TO appuser;


--
-- Name: FUNCTION pgp_sym_decrypt(bytea, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_sym_decrypt(bytea, text) TO appuser;


--
-- Name: FUNCTION pgp_sym_decrypt(bytea, text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_sym_decrypt(bytea, text, text) TO appuser;


--
-- Name: FUNCTION pgp_sym_decrypt_bytea(bytea, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_sym_decrypt_bytea(bytea, text) TO appuser;


--
-- Name: FUNCTION pgp_sym_decrypt_bytea(bytea, text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_sym_decrypt_bytea(bytea, text, text) TO appuser;


--
-- Name: FUNCTION pgp_sym_encrypt(text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_sym_encrypt(text, text) TO appuser;


--
-- Name: FUNCTION pgp_sym_encrypt(text, text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_sym_encrypt(text, text, text) TO appuser;


--
-- Name: FUNCTION pgp_sym_encrypt_bytea(bytea, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_sym_encrypt_bytea(bytea, text) TO appuser;


--
-- Name: FUNCTION pgp_sym_encrypt_bytea(bytea, text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.pgp_sym_encrypt_bytea(bytea, text, text) TO appuser;


--
-- Name: FUNCTION regexp_match(public.citext, public.citext); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.regexp_match(public.citext, public.citext) TO appuser;


--
-- Name: FUNCTION regexp_match(public.citext, public.citext, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.regexp_match(public.citext, public.citext, text) TO appuser;


--
-- Name: FUNCTION regexp_matches(public.citext, public.citext); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.regexp_matches(public.citext, public.citext) TO appuser;


--
-- Name: FUNCTION regexp_matches(public.citext, public.citext, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.regexp_matches(public.citext, public.citext, text) TO appuser;


--
-- Name: FUNCTION regexp_replace(public.citext, public.citext, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.regexp_replace(public.citext, public.citext, text) TO appuser;


--
-- Name: FUNCTION regexp_replace(public.citext, public.citext, text, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.regexp_replace(public.citext, public.citext, text, text) TO appuser;


--
-- Name: FUNCTION regexp_split_to_array(public.citext, public.citext); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.regexp_split_to_array(public.citext, public.citext) TO appuser;


--
-- Name: FUNCTION regexp_split_to_array(public.citext, public.citext, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.regexp_split_to_array(public.citext, public.citext, text) TO appuser;


--
-- Name: FUNCTION regexp_split_to_table(public.citext, public.citext); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.regexp_split_to_table(public.citext, public.citext) TO appuser;


--
-- Name: FUNCTION regexp_split_to_table(public.citext, public.citext, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.regexp_split_to_table(public.citext, public.citext, text) TO appuser;


--
-- Name: FUNCTION replace(public.citext, public.citext, public.citext); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.replace(public.citext, public.citext, public.citext) TO appuser;


--
-- Name: FUNCTION split_part(public.citext, public.citext, integer); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.split_part(public.citext, public.citext, integer) TO appuser;


--
-- Name: FUNCTION strpos(public.citext, public.citext); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.strpos(public.citext, public.citext) TO appuser;


--
-- Name: FUNCTION texticlike(public.citext, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.texticlike(public.citext, text) TO appuser;


--
-- Name: FUNCTION texticlike(public.citext, public.citext); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.texticlike(public.citext, public.citext) TO appuser;


--
-- Name: FUNCTION texticnlike(public.citext, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.texticnlike(public.citext, text) TO appuser;


--
-- Name: FUNCTION texticnlike(public.citext, public.citext); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.texticnlike(public.citext, public.citext) TO appuser;


--
-- Name: FUNCTION texticregexeq(public.citext, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.texticregexeq(public.citext, text) TO appuser;


--
-- Name: FUNCTION texticregexeq(public.citext, public.citext); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.texticregexeq(public.citext, public.citext) TO appuser;


--
-- Name: FUNCTION texticregexne(public.citext, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.texticregexne(public.citext, text) TO appuser;


--
-- Name: FUNCTION texticregexne(public.citext, public.citext); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.texticregexne(public.citext, public.citext) TO appuser;


--
-- Name: FUNCTION translate(public.citext, public.citext, text); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.translate(public.citext, public.citext, text) TO appuser;


--
-- Name: FUNCTION max(public.citext); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.max(public.citext) TO appuser;


--
-- Name: FUNCTION min(public.citext); Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON FUNCTION public.min(public.citext) TO appuser;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON SEQUENCES TO appuser;


--
-- Name: DEFAULT PRIVILEGES FOR TYPES; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON TYPES TO appuser;


--
-- Name: DEFAULT PRIVILEGES FOR FUNCTIONS; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON FUNCTIONS TO appuser;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON TABLES TO appuser;


--
-- PostgreSQL database dump complete
--

\unrestrict fRVRpi7JFRyexNG2htE33nRBChSW7mqgl9B9wdzqvMC4Q7iRJJG5PFtbxdCwVDl

