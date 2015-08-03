-- 
-- Created by SQL::Translator::Producer::PostgreSQL
-- Created on Fri Jul 31 19:07:28 2015
-- 
;
--
-- Table: addresses
--
CREATE TABLE "addresses" (
  "addresses_id" serial NOT NULL,
  "users_id" integer NOT NULL,
  "type" character varying(16) DEFAULT '' NOT NULL,
  "archived" boolean DEFAULT '0' NOT NULL,
  "first_name" character varying(255) DEFAULT '' NOT NULL,
  "last_name" character varying(255) DEFAULT '' NOT NULL,
  "company" character varying(255) DEFAULT '' NOT NULL,
  "address" character varying(255) DEFAULT '' NOT NULL,
  "address_2" character varying(255) DEFAULT '' NOT NULL,
  "postal_code" character varying(255) DEFAULT '' NOT NULL,
  "city" character varying(255) DEFAULT '' NOT NULL,
  "phone" character varying(32) DEFAULT '' NOT NULL,
  "states_id" integer,
  "country_iso_code" character(2) NOT NULL,
  "priority" integer DEFAULT 0 NOT NULL,
  "created" timestamp NOT NULL,
  "last_modified" timestamp NOT NULL,
  "latitude" float(20),
  "longitude" float(30),
  PRIMARY KEY ("addresses_id")
);
CREATE INDEX "addresses_idx_country_iso_code" on "addresses" ("country_iso_code");
CREATE INDEX "addresses_idx_states_id" on "addresses" ("states_id");
CREATE INDEX "addresses_idx_users_id" on "addresses" ("users_id");

;
--
-- Table: attribute_values
--
CREATE TABLE "attribute_values" (
  "attribute_values_id" serial NOT NULL,
  "attributes_id" integer NOT NULL,
  "value" character varying(255) NOT NULL,
  "title" character varying(255) NOT NULL,
  "priority" integer DEFAULT 0 NOT NULL,
  PRIMARY KEY ("attribute_values_id"),
  CONSTRAINT "attribute_values_attributes_id_value" UNIQUE ("attributes_id", "value")
);
CREATE INDEX "attribute_values_idx_attributes_id" on "attribute_values" ("attributes_id");

;
--
-- Table: attributes
--
CREATE TABLE "attributes" (
  "attributes_id" serial NOT NULL,
  "name" character varying(255) NOT NULL,
  "type" character varying(255) DEFAULT '' NOT NULL,
  "title" character varying(255) NOT NULL,
  "dynamic" boolean DEFAULT '0' NOT NULL,
  "priority" integer DEFAULT 0 NOT NULL,
  PRIMARY KEY ("attributes_id"),
  CONSTRAINT "attributes_name_type" UNIQUE ("name", "type")
);

;
--
-- Table: cart_products
--
CREATE TABLE "cart_products" (
  "cart_products_id" serial NOT NULL,
  "carts_id" integer NOT NULL,
  "sku" character varying(64) NOT NULL,
  "cart_position" integer NOT NULL,
  "quantity" integer DEFAULT 1 NOT NULL,
  "created" timestamp NOT NULL,
  "last_modified" timestamp NOT NULL,
  PRIMARY KEY ("cart_products_id")
);
CREATE INDEX "cart_products_idx_carts_id" on "cart_products" ("carts_id");
CREATE INDEX "cart_products_idx_sku" on "cart_products" ("sku");

;
--
-- Table: carts
--
CREATE TABLE "carts" (
  "carts_id" serial NOT NULL,
  "name" character varying(255) DEFAULT '' NOT NULL,
  "users_id" integer,
  "sessions_id" character varying(255),
  "created" timestamp NOT NULL,
  "last_modified" timestamp NOT NULL,
  PRIMARY KEY ("carts_id"),
  CONSTRAINT "carts_name_sessions_id" UNIQUE ("name", "sessions_id")
);
CREATE INDEX "carts_idx_sessions_id" on "carts" ("sessions_id");
CREATE INDEX "carts_idx_users_id" on "carts" ("users_id");

;
--
-- Table: conferences
--
CREATE TABLE "conferences" (
  "conferences_id" serial NOT NULL,
  "name" character varying(128) NOT NULL,
  "start_date" date,
  PRIMARY KEY ("conferences_id"),
  CONSTRAINT "conferences_name" UNIQUE ("name")
);

;
--
-- Table: countries
--
CREATE TABLE "countries" (
  "country_iso_code" character(2) NOT NULL,
  "scope" character varying(32) DEFAULT '' NOT NULL,
  "name" character varying(255) NOT NULL,
  "priority" integer DEFAULT 0 NOT NULL,
  "show_states" boolean DEFAULT '0' NOT NULL,
  "active" boolean DEFAULT '1' NOT NULL,
  PRIMARY KEY ("country_iso_code")
);

;
--
-- Table: inventories
--
CREATE TABLE "inventories" (
  "sku" character varying(64) NOT NULL,
  "quantity" integer DEFAULT 0 NOT NULL,
  PRIMARY KEY ("sku")
);

;
--
-- Table: media_displays
--
CREATE TABLE "media_displays" (
  "media_displays_id" serial NOT NULL,
  "media_types_id" integer NOT NULL,
  "type" character varying(255) NOT NULL,
  "name" character varying(255),
  "path" character varying(255),
  "size" character varying(255),
  PRIMARY KEY ("media_displays_id"),
  CONSTRAINT "media_types_id_type_unique" UNIQUE ("media_types_id", "type")
);
CREATE INDEX "media_displays_idx_media_types_id" on "media_displays" ("media_types_id");

;
--
-- Table: media_products
--
CREATE TABLE "media_products" (
  "media_id" integer NOT NULL,
  "sku" character varying(64) NOT NULL,
  PRIMARY KEY ("media_id", "sku")
);
CREATE INDEX "media_products_idx_media_id" on "media_products" ("media_id");
CREATE INDEX "media_products_idx_sku" on "media_products" ("sku");

;
--
-- Table: media_types
--
CREATE TABLE "media_types" (
  "media_types_id" serial NOT NULL,
  "type" character varying(32) NOT NULL,
  PRIMARY KEY ("media_types_id"),
  CONSTRAINT "media_types_type" UNIQUE ("type")
);

;
--
-- Table: merchandising_attributes
--
CREATE TABLE "merchandising_attributes" (
  "merchandising_attributes_id" serial NOT NULL,
  "merchandising_products_id" integer NOT NULL,
  "name" character varying(32) NOT NULL,
  "value" text NOT NULL,
  PRIMARY KEY ("merchandising_attributes_id")
);
CREATE INDEX "merchandising_attributes_idx_merchandising_products_id" on "merchandising_attributes" ("merchandising_products_id");

;
--
-- Table: merchandising_products
--
CREATE TABLE "merchandising_products" (
  "merchandising_products_id" serial NOT NULL,
  "sku" character varying(64) NOT NULL,
  "sku_related" character varying(64),
  "type" character varying(32) DEFAULT '' NOT NULL,
  PRIMARY KEY ("merchandising_products_id"),
  CONSTRAINT "merchandising_products_sku_sku_related_type" UNIQUE ("sku", "sku_related", "type")
);
CREATE INDEX "merchandising_products_idx_sku" on "merchandising_products" ("sku");
CREATE INDEX "merchandising_products_idx_sku_related" on "merchandising_products" ("sku_related");

;
--
-- Table: message_types
--
CREATE TABLE "message_types" (
  "message_types_id" serial NOT NULL,
  "name" character varying(255) NOT NULL,
  "active" boolean DEFAULT '1' NOT NULL,
  PRIMARY KEY ("message_types_id"),
  CONSTRAINT "message_types_name" UNIQUE ("name")
);

;
--
-- Table: navigation_attribute_values
--
CREATE TABLE "navigation_attribute_values" (
  "navigation_attribute_values_id" serial NOT NULL,
  "navigation_attributes_id" integer NOT NULL,
  "attribute_values_id" integer NOT NULL,
  PRIMARY KEY ("navigation_attribute_values_id")
);
CREATE INDEX "navigation_attribute_values_idx_attribute_values_id" on "navigation_attribute_values" ("attribute_values_id");
CREATE INDEX "navigation_attribute_values_idx_navigation_attributes_id" on "navigation_attribute_values" ("navigation_attributes_id");

;
--
-- Table: navigation_attributes
--
CREATE TABLE "navigation_attributes" (
  "navigation_attributes_id" serial NOT NULL,
  "navigation_id" integer NOT NULL,
  "attributes_id" integer NOT NULL,
  PRIMARY KEY ("navigation_attributes_id"),
  CONSTRAINT "navigation_id_attributes_id" UNIQUE ("navigation_id", "attributes_id")
);
CREATE INDEX "navigation_attributes_idx_attributes_id" on "navigation_attributes" ("attributes_id");
CREATE INDEX "navigation_attributes_idx_navigation_id" on "navigation_attributes" ("navigation_id");

;
--
-- Table: navigation_products
--
CREATE TABLE "navigation_products" (
  "sku" character varying(64) NOT NULL,
  "navigation_id" integer NOT NULL,
  "type" character varying(16),
  "priority" integer DEFAULT 0 NOT NULL,
  PRIMARY KEY ("sku", "navigation_id")
);
CREATE INDEX "navigation_products_idx_navigation_id" on "navigation_products" ("navigation_id");
CREATE INDEX "navigation_products_idx_sku" on "navigation_products" ("sku");

;
--
-- Table: navigations
--
CREATE TABLE "navigations" (
  "navigation_id" serial NOT NULL,
  "uri" character varying(255),
  "type" character varying(32) DEFAULT '' NOT NULL,
  "scope" character varying(32) DEFAULT '' NOT NULL,
  "name" character varying(255) DEFAULT '' NOT NULL,
  "description" character varying(1024) DEFAULT '' NOT NULL,
  "alias" integer,
  "parent_id" integer,
  "priority" integer DEFAULT 0 NOT NULL,
  "product_count" integer DEFAULT 0 NOT NULL,
  "created" timestamp NOT NULL,
  "last_modified" timestamp NOT NULL,
  "active" boolean DEFAULT '1' NOT NULL,
  PRIMARY KEY ("navigation_id"),
  CONSTRAINT "navigations_uri" UNIQUE ("uri")
);
CREATE INDEX "navigations_idx_parent_id" on "navigations" ("parent_id");

;
--
-- Table: orderlines
--
CREATE TABLE "orderlines" (
  "orderlines_id" serial NOT NULL,
  "orders_id" integer NOT NULL,
  "order_position" integer DEFAULT 0 NOT NULL,
  "sku" character varying(64) NOT NULL,
  "name" character varying(255) NOT NULL,
  "short_description" character varying(500) DEFAULT '' NOT NULL,
  "description" text NOT NULL,
  "weight" numeric(10,3) DEFAULT 0.0 NOT NULL,
  "quantity" integer NOT NULL,
  "price" numeric(10,2) NOT NULL,
  "subtotal" numeric(11,2) NOT NULL,
  "shipping" numeric(11,2) DEFAULT 0.0 NOT NULL,
  "handling" numeric(11,2) DEFAULT 0.0 NOT NULL,
  "salestax" numeric(11,2) DEFAULT 0.0 NOT NULL,
  "status" character varying(24) DEFAULT '' NOT NULL,
  PRIMARY KEY ("orderlines_id")
);
CREATE INDEX "orderlines_idx_orders_id" on "orderlines" ("orders_id");
CREATE INDEX "orderlines_idx_sku" on "orderlines" ("sku");

;
--
-- Table: permissions
--
CREATE TABLE "permissions" (
  "permissions_id" serial NOT NULL,
  "roles_id" integer NOT NULL,
  "perm" character varying(255) NOT NULL,
  PRIMARY KEY ("permissions_id")
);
CREATE INDEX "permissions_idx_roles_id" on "permissions" ("roles_id");

;
--
-- Table: price_modifiers
--
CREATE TABLE "price_modifiers" (
  "price_modifiers_id" serial NOT NULL,
  "sku" character varying(64) NOT NULL,
  "quantity" integer DEFAULT 0 NOT NULL,
  "roles_id" integer,
  "price" numeric(10,2) NOT NULL,
  "discount" numeric(7,4),
  "start_date" date,
  "end_date" date,
  PRIMARY KEY ("price_modifiers_id")
);
CREATE INDEX "price_modifiers_idx_sku" on "price_modifiers" ("sku");
CREATE INDEX "price_modifiers_idx_roles_id" on "price_modifiers" ("roles_id");

;
--
-- Table: product_attribute_values
--
CREATE TABLE "product_attribute_values" (
  "product_attribute_values_id" serial NOT NULL,
  "product_attributes_id" integer NOT NULL,
  "attribute_values_id" integer NOT NULL,
  PRIMARY KEY ("product_attribute_values_id")
);
CREATE INDEX "product_attribute_values_idx_attribute_values_id" on "product_attribute_values" ("attribute_values_id");
CREATE INDEX "product_attribute_values_idx_product_attributes_id" on "product_attribute_values" ("product_attributes_id");

;
--
-- Table: product_attributes
--
CREATE TABLE "product_attributes" (
  "product_attributes_id" serial NOT NULL,
  "sku" character varying(64) NOT NULL,
  "attributes_id" integer NOT NULL,
  "canonical" boolean DEFAULT '1' NOT NULL,
  PRIMARY KEY ("product_attributes_id"),
  CONSTRAINT "sku_attributes_id" UNIQUE ("sku", "attributes_id")
);
CREATE INDEX "product_attributes_idx_attributes_id" on "product_attributes" ("attributes_id");
CREATE INDEX "product_attributes_idx_sku" on "product_attributes" ("sku");

;
--
-- Table: products
--
CREATE TABLE "products" (
  "sku" character varying(64) NOT NULL,
  "manufacturer_sku" character varying(64),
  "name" character varying(255) NOT NULL,
  "short_description" character varying(500) DEFAULT '' NOT NULL,
  "description" text NOT NULL,
  "price" numeric(10,2) DEFAULT 0.0 NOT NULL,
  "uri" character varying(255),
  "weight" numeric(10,2) DEFAULT 0 NOT NULL,
  "priority" integer DEFAULT 0 NOT NULL,
  "gtin" character varying(32),
  "canonical_sku" character varying(64),
  "active" boolean DEFAULT '1' NOT NULL,
  "inventory_exempt" boolean DEFAULT '0' NOT NULL,
  "created" timestamp NOT NULL,
  "last_modified" timestamp NOT NULL,
  PRIMARY KEY ("sku"),
  CONSTRAINT "products_gtin" UNIQUE ("gtin"),
  CONSTRAINT "products_uri" UNIQUE ("uri")
);
CREATE INDEX "products_idx_canonical_sku" on "products" ("canonical_sku");

;
--
-- Table: roles
--
CREATE TABLE "roles" (
  "roles_id" serial NOT NULL,
  "name" character varying(32) NOT NULL,
  "label" character varying(255) NOT NULL,
  "description" text NOT NULL,
  PRIMARY KEY ("roles_id"),
  CONSTRAINT "roles_name" UNIQUE ("name")
);

;
--
-- Table: sessions
--
CREATE TABLE "sessions" (
  "sessions_id" character varying(255) NOT NULL,
  "session_data" text NOT NULL,
  "created" timestamp NOT NULL,
  "last_modified" timestamp NOT NULL,
  PRIMARY KEY ("sessions_id")
);

;
--
-- Table: settings
--
CREATE TABLE "settings" (
  "settings_id" serial NOT NULL,
  "scope" character varying(32) NOT NULL,
  "site" character varying(32) DEFAULT '' NOT NULL,
  "name" character varying(32) NOT NULL,
  "value" text NOT NULL,
  "category" character varying(32) DEFAULT '' NOT NULL,
  PRIMARY KEY ("settings_id")
);

;
--
-- Table: shipment_carriers
--
CREATE TABLE "shipment_carriers" (
  "shipment_carriers_id" serial NOT NULL,
  "name" character varying(255) NOT NULL,
  "title" character varying(255) DEFAULT '' NOT NULL,
  "account_number" character varying(255) DEFAULT '' NOT NULL,
  "active" boolean DEFAULT '1' NOT NULL,
  PRIMARY KEY ("shipment_carriers_id")
);

;
--
-- Table: shipment_destinations
--
CREATE TABLE "shipment_destinations" (
  "shipment_destinations_id" serial NOT NULL,
  "zones_id" integer NOT NULL,
  "shipment_methods_id" integer NOT NULL,
  "active" boolean DEFAULT '1' NOT NULL,
  PRIMARY KEY ("shipment_destinations_id")
);
CREATE INDEX "shipment_destinations_idx_shipment_methods_id" on "shipment_destinations" ("shipment_methods_id");
CREATE INDEX "shipment_destinations_idx_zones_id" on "shipment_destinations" ("zones_id");

;
--
-- Table: shipment_methods
--
CREATE TABLE "shipment_methods" (
  "shipment_methods_id" serial NOT NULL,
  "name" character varying(255) DEFAULT '' NOT NULL,
  "title" character varying(255) DEFAULT '' NOT NULL,
  "shipment_carriers_id" integer NOT NULL,
  "active" boolean DEFAULT '1' NOT NULL,
  "created" timestamp NOT NULL,
  "last_modified" timestamp NOT NULL,
  PRIMARY KEY ("shipment_methods_id")
);
CREATE INDEX "shipment_methods_idx_shipment_carriers_id" on "shipment_methods" ("shipment_carriers_id");

;
--
-- Table: shipment_rates
--
CREATE TABLE "shipment_rates" (
  "shipment_rates_id" serial NOT NULL,
  "zones_id" integer NOT NULL,
  "shipment_methods_id" integer NOT NULL,
  "value_type" character varying(64),
  "value_unit" character varying(64),
  "min_value" numeric(10,2) DEFAULT 0.0 NOT NULL,
  "max_value" numeric(10,2) DEFAULT 0.0 NOT NULL,
  "price" numeric(10,2) DEFAULT 0.0 NOT NULL,
  "valid_from" date NOT NULL,
  "valid_to" date,
  "created" timestamp NOT NULL,
  "last_modified" timestamp NOT NULL,
  PRIMARY KEY ("shipment_rates_id")
);
CREATE INDEX "shipment_rates_idx_shipment_methods_id" on "shipment_rates" ("shipment_methods_id");
CREATE INDEX "shipment_rates_idx_zones_id" on "shipment_rates" ("zones_id");

;
--
-- Table: shipments
--
CREATE TABLE "shipments" (
  "shipments_id" serial NOT NULL,
  "tracking_number" character varying(255) DEFAULT '' NOT NULL,
  "shipment_carriers_id" integer NOT NULL,
  "shipment_methods_id" integer NOT NULL,
  "created" timestamp NOT NULL,
  "last_modified" timestamp NOT NULL,
  PRIMARY KEY ("shipments_id")
);
CREATE INDEX "shipments_idx_shipment_carriers_id" on "shipments" ("shipment_carriers_id");
CREATE INDEX "shipments_idx_shipment_methods_id" on "shipments" ("shipment_methods_id");

;
--
-- Table: states
--
CREATE TABLE "states" (
  "states_id" serial NOT NULL,
  "scope" character varying(32) DEFAULT '' NOT NULL,
  "country_iso_code" character(2) NOT NULL,
  "state_iso_code" character varying(6) DEFAULT '' NOT NULL,
  "name" character varying(255) DEFAULT '' NOT NULL,
  "priority" integer DEFAULT 0 NOT NULL,
  "active" boolean DEFAULT '1' NOT NULL,
  PRIMARY KEY ("states_id"),
  CONSTRAINT "states_state_country" UNIQUE ("country_iso_code", "state_iso_code")
);
CREATE INDEX "states_idx_country_iso_code" on "states" ("country_iso_code");

;
--
-- Table: taxes
--
CREATE TABLE "taxes" (
  "taxes_id" serial NOT NULL,
  "tax_name" character varying(64) NOT NULL,
  "description" character varying(64) NOT NULL,
  "percent" numeric(7,4) NOT NULL,
  "decimal_places" integer DEFAULT 2 NOT NULL,
  "rounding" character(1),
  "valid_from" date NOT NULL,
  "valid_to" date,
  "country_iso_code" character(2),
  "states_id" integer,
  "created" timestamp NOT NULL,
  "last_modified" timestamp NOT NULL,
  PRIMARY KEY ("taxes_id")
);
CREATE INDEX "taxes_idx_country_iso_code" on "taxes" ("country_iso_code");
CREATE INDEX "taxes_idx_states_id" on "taxes" ("states_id");
CREATE INDEX "taxes_idx_tax_name" on "taxes" ("tax_name");
CREATE INDEX "taxes_idx_valid_from" on "taxes" ("valid_from");
CREATE INDEX "taxes_idx_valid_to" on "taxes" ("valid_to");

;
--
-- Table: uri_redirects
--
CREATE TABLE "uri_redirects" (
  "uri_source" character varying(255) NOT NULL,
  "uri_target" character varying(255) NOT NULL,
  "status_code" integer DEFAULT 301 NOT NULL,
  "created" timestamp NOT NULL,
  "last_used" timestamp NOT NULL,
  PRIMARY KEY ("uri_source")
);

;
--
-- Table: user_attribute_values
--
CREATE TABLE "user_attribute_values" (
  "user_attribute_values_id" serial NOT NULL,
  "user_attributes_id" integer NOT NULL,
  "attribute_values_id" integer NOT NULL,
  PRIMARY KEY ("user_attribute_values_id")
);
CREATE INDEX "user_attribute_values_idx_attribute_values_id" on "user_attribute_values" ("attribute_values_id");
CREATE INDEX "user_attribute_values_idx_user_attributes_id" on "user_attribute_values" ("user_attributes_id");

;
--
-- Table: user_attributes
--
CREATE TABLE "user_attributes" (
  "user_attributes_id" serial NOT NULL,
  "users_id" integer NOT NULL,
  "attributes_id" integer NOT NULL,
  PRIMARY KEY ("user_attributes_id"),
  CONSTRAINT "users_id_attributes_id" UNIQUE ("users_id", "attributes_id")
);
CREATE INDEX "user_attributes_idx_attributes_id" on "user_attributes" ("attributes_id");
CREATE INDEX "user_attributes_idx_users_id" on "user_attributes" ("users_id");

;
--
-- Table: zone_countries
--
CREATE TABLE "zone_countries" (
  "zones_id" integer NOT NULL,
  "country_iso_code" character(2) NOT NULL,
  PRIMARY KEY ("zones_id", "country_iso_code")
);
CREATE INDEX "zone_countries_idx_country_iso_code" on "zone_countries" ("country_iso_code");
CREATE INDEX "zone_countries_idx_zones_id" on "zone_countries" ("zones_id");

;
--
-- Table: zone_states
--
CREATE TABLE "zone_states" (
  "zones_id" integer NOT NULL,
  "states_id" integer NOT NULL,
  PRIMARY KEY ("zones_id", "states_id")
);
CREATE INDEX "zone_states_idx_states_id" on "zone_states" ("states_id");
CREATE INDEX "zone_states_idx_zones_id" on "zone_states" ("zones_id");

;
--
-- Table: zones
--
CREATE TABLE "zones" (
  "zones_id" serial NOT NULL,
  "zone" character varying(255) NOT NULL,
  "created" timestamp NOT NULL,
  "last_modified" timestamp NOT NULL,
  PRIMARY KEY ("zones_id"),
  CONSTRAINT "zones_zone" UNIQUE ("zone")
);

;
--
-- Table: orders
--
CREATE TABLE "orders" (
  "orders_id" serial NOT NULL,
  "order_number" character varying(24) NOT NULL,
  "order_date" timestamp,
  "users_id" integer NOT NULL,
  "email" character varying(255) DEFAULT '' NOT NULL,
  "shipping_addresses_id" integer NOT NULL,
  "billing_addresses_id" integer NOT NULL,
  "weight" numeric(11,3) DEFAULT 0.0 NOT NULL,
  "payment_method" character varying(255) DEFAULT '' NOT NULL,
  "payment_number" character varying(255) DEFAULT '' NOT NULL,
  "payment_status" character varying(255) DEFAULT '' NOT NULL,
  "shipping_method" character varying(255) DEFAULT '' NOT NULL,
  "subtotal" numeric(11,2) DEFAULT 0.0 NOT NULL,
  "shipping" numeric(11,2) DEFAULT 0.0 NOT NULL,
  "handling" numeric(11,2) DEFAULT 0.0 NOT NULL,
  "salestax" numeric(11,2) DEFAULT 0.0 NOT NULL,
  "total_cost" numeric(11,2) DEFAULT 0.0 NOT NULL,
  PRIMARY KEY ("orders_id"),
  CONSTRAINT "orders_order_number" UNIQUE ("order_number")
);
CREATE INDEX "orders_idx_billing_addresses_id" on "orders" ("billing_addresses_id");
CREATE INDEX "orders_idx_shipping_addresses_id" on "orders" ("shipping_addresses_id");
CREATE INDEX "orders_idx_users_id" on "orders" ("users_id");

;
--
-- Table: payment_orders
--
CREATE TABLE "payment_orders" (
  "payment_orders_id" serial NOT NULL,
  "payment_mode" character varying(32) DEFAULT '' NOT NULL,
  "payment_action" character varying(32) DEFAULT '' NOT NULL,
  "payment_id" character varying(32) DEFAULT '' NOT NULL,
  "auth_code" character varying(255) DEFAULT '' NOT NULL,
  "users_id" integer,
  "sessions_id" character varying(255),
  "orders_id" integer,
  "amount" numeric(11,2) DEFAULT 0.0 NOT NULL,
  "status" character varying(32) DEFAULT '' NOT NULL,
  "payment_sessions_id" character varying(255) DEFAULT '' NOT NULL,
  "payment_error_code" character varying(32) DEFAULT '' NOT NULL,
  "payment_error_message" text,
  "payment_fee" numeric(11,2) DEFAULT 0.0 NOT NULL,
  "created" timestamp NOT NULL,
  "last_modified" timestamp NOT NULL,
  PRIMARY KEY ("payment_orders_id")
);
CREATE INDEX "payment_orders_idx_orders_id" on "payment_orders" ("orders_id");
CREATE INDEX "payment_orders_idx_sessions_id" on "payment_orders" ("sessions_id");
CREATE INDEX "payment_orders_idx_users_id" on "payment_orders" ("users_id");

;
--
-- Table: users
--
CREATE TABLE "users" (
  "users_id" serial NOT NULL,
  "username" character varying(255) NOT NULL,
  "nickname" character varying(255),
  "email" character varying(255) DEFAULT '' NOT NULL,
  "password" character varying(60) DEFAULT '' NOT NULL,
  "first_name" character varying(255) DEFAULT '' NOT NULL,
  "last_name" character varying(255) DEFAULT '' NOT NULL,
  "last_login" timestamp,
  "fail_count" integer DEFAULT 0 NOT NULL,
  "reset_expires" timestamp,
  "reset_token" character varying(255),
  "is_anonymous" boolean DEFAULT '0' NOT NULL,
  "created" timestamp NOT NULL,
  "last_modified" timestamp NOT NULL,
  "active" boolean DEFAULT '1' NOT NULL,
  "bio" character varying(2048) DEFAULT '' NOT NULL,
  "media_id" integer,
  "monger_groups" character varying(256) DEFAULT '' NOT NULL,
  "pause_id" character varying(128) DEFAULT '' NOT NULL,
  PRIMARY KEY ("users_id"),
  CONSTRAINT "users_nickname" UNIQUE ("nickname"),
  CONSTRAINT "users_username" UNIQUE ("username")
);
CREATE INDEX "users_idx_media_id" on "users" ("media_id");
CREATE INDEX "users_idx_reset_token" on "users" ("reset_token");

;
--
-- Table: conference_tickets
--
CREATE TABLE "conference_tickets" (
  "conferences_id" integer NOT NULL,
  "sku" character varying(64) NOT NULL,
  PRIMARY KEY ("conferences_id", "sku")
);
CREATE INDEX "conference_tickets_idx_conferences_id" on "conference_tickets" ("conferences_id");
CREATE INDEX "conference_tickets_idx_sku" on "conference_tickets" ("sku");

;
--
-- Table: medias
--
CREATE TABLE "medias" (
  "media_id" serial NOT NULL,
  "file" character varying(255) DEFAULT '' NOT NULL,
  "uri" character varying(255) DEFAULT '' NOT NULL,
  "mime_type" character varying(255) DEFAULT '' NOT NULL,
  "label" character varying(255) DEFAULT '' NOT NULL,
  "author_users_id" integer,
  "created" timestamp NOT NULL,
  "last_modified" timestamp NOT NULL,
  "active" boolean DEFAULT '1' NOT NULL,
  "media_types_id" integer NOT NULL,
  PRIMARY KEY ("media_id"),
  CONSTRAINT "media_id_media_types_id_unique" UNIQUE ("media_id", "media_types_id"),
  CONSTRAINT "medias_file" UNIQUE ("file")
);
CREATE INDEX "medias_idx_author_users_id" on "medias" ("author_users_id");
CREATE INDEX "medias_idx_media_types_id" on "medias" ("media_types_id");

;
--
-- Table: order_statuses
--
CREATE TABLE "order_statuses" (
  "order_status_id" serial NOT NULL,
  "orders_id" integer NOT NULL,
  "status" character varying(32) NOT NULL,
  "created" timestamp NOT NULL,
  PRIMARY KEY ("order_status_id")
);
CREATE INDEX "order_statuses_idx_orders_id" on "order_statuses" ("orders_id");

;
--
-- Table: user_roles
--
CREATE TABLE "user_roles" (
  "users_id" integer NOT NULL,
  "roles_id" integer NOT NULL,
  PRIMARY KEY ("users_id", "roles_id")
);
CREATE INDEX "user_roles_idx_roles_id" on "user_roles" ("roles_id");
CREATE INDEX "user_roles_idx_users_id" on "user_roles" ("users_id");

;
--
-- Table: conference_attendees
--
CREATE TABLE "conference_attendees" (
  "conferences_id" integer NOT NULL,
  "users_id" integer NOT NULL,
  "confirmed" boolean DEFAULT '0' NOT NULL,
  PRIMARY KEY ("conferences_id", "users_id")
);
CREATE INDEX "conference_attendees_idx_conferences_id" on "conference_attendees" ("conferences_id");
CREATE INDEX "conference_attendees_idx_users_id" on "conference_attendees" ("users_id");

;
--
-- Table: messages
--
CREATE TABLE "messages" (
  "messages_id" serial NOT NULL,
  "title" character varying(255) DEFAULT '' NOT NULL,
  "message_types_id" integer NOT NULL,
  "uri" character varying(255),
  "format" character varying(32) DEFAULT 'plain' NOT NULL,
  "content" text NOT NULL,
  "summary" character varying(1024) DEFAULT '' NOT NULL,
  "author_users_id" integer,
  "rating" numeric(4,2) DEFAULT 0 NOT NULL,
  "recommend" boolean,
  "public" boolean DEFAULT '0' NOT NULL,
  "approved" boolean DEFAULT '0' NOT NULL,
  "approved_by_users_id" integer,
  "parent_id" integer,
  "created" timestamp NOT NULL,
  "last_modified" timestamp NOT NULL,
  "tags" character varying(256) DEFAULT '' NOT NULL,
  PRIMARY KEY ("messages_id"),
  CONSTRAINT "messages_uri" UNIQUE ("uri")
);
CREATE INDEX "messages_idx_parent_id" on "messages" ("parent_id");
CREATE INDEX "messages_idx_approved_by_users_id" on "messages" ("approved_by_users_id");
CREATE INDEX "messages_idx_author_users_id" on "messages" ("author_users_id");
CREATE INDEX "messages_idx_message_types_id" on "messages" ("message_types_id");

;
--
-- Table: orderlines_shippings
--
CREATE TABLE "orderlines_shippings" (
  "orderlines_id" integer NOT NULL,
  "addresses_id" integer NOT NULL,
  "shipments_id" integer NOT NULL,
  PRIMARY KEY ("orderlines_id", "addresses_id")
);
CREATE INDEX "orderlines_shippings_idx_addresses_id" on "orderlines_shippings" ("addresses_id");
CREATE INDEX "orderlines_shippings_idx_orderlines_id" on "orderlines_shippings" ("orderlines_id");
CREATE INDEX "orderlines_shippings_idx_shipments_id" on "orderlines_shippings" ("shipments_id");

;
--
-- Table: talks
--
CREATE TABLE "talks" (
  "talks_id" serial NOT NULL,
  "author_id" integer,
  "conferences_id" integer NOT NULL,
  "duration" smallint NOT NULL,
  "title" character varying(255) NOT NULL,
  "tags" character varying(255) NOT NULL,
  "abstract" character varying(2048) DEFAULT '' NOT NULL,
  "url" character varying(255) DEFAULT '' NOT NULL,
  "comments" character varying(1024) DEFAULT '' NOT NULL,
  "accepted" boolean DEFAULT '0' NOT NULL,
  "confirmed" boolean DEFAULT '0' NOT NULL,
  "lightning" boolean DEFAULT '0' NOT NULL,
  "start_time" timestamp,
  "room" character varying(128) DEFAULT '' NOT NULL,
  PRIMARY KEY ("talks_id")
);
CREATE INDEX "talks_idx_author_id" on "talks" ("author_id");
CREATE INDEX "talks_idx_conferences_id" on "talks" ("conferences_id");

;
--
-- Table: attendee_talks
--
CREATE TABLE "attendee_talks" (
  "users_id" integer NOT NULL,
  "talks_id" integer NOT NULL,
  PRIMARY KEY ("users_id", "talks_id")
);
CREATE INDEX "attendee_talks_idx_talks_id" on "attendee_talks" ("talks_id");
CREATE INDEX "attendee_talks_idx_users_id" on "attendee_talks" ("users_id");

;
--
-- Table: product_reviews
--
CREATE TABLE "product_reviews" (
  "messages_id" integer NOT NULL,
  "sku" character varying(64) NOT NULL,
  PRIMARY KEY ("messages_id", "sku")
);
CREATE INDEX "product_reviews_idx_messages_id" on "product_reviews" ("messages_id");
CREATE INDEX "product_reviews_idx_sku" on "product_reviews" ("sku");

;
--
-- Table: order_comments
--
CREATE TABLE "order_comments" (
  "messages_id" integer NOT NULL,
  "orders_id" integer NOT NULL,
  PRIMARY KEY ("messages_id", "orders_id")
);
CREATE INDEX "order_comments_idx_messages_id" on "order_comments" ("messages_id");
CREATE INDEX "order_comments_idx_orders_id" on "order_comments" ("orders_id");

;
--
-- Foreign Key Definitions
--

;
ALTER TABLE "addresses" ADD CONSTRAINT "addresses_fk_country_iso_code" FOREIGN KEY ("country_iso_code")
  REFERENCES "countries" ("country_iso_code") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "addresses" ADD CONSTRAINT "addresses_fk_states_id" FOREIGN KEY ("states_id")
  REFERENCES "states" ("states_id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "addresses" ADD CONSTRAINT "addresses_fk_users_id" FOREIGN KEY ("users_id")
  REFERENCES "users" ("users_id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "attribute_values" ADD CONSTRAINT "attribute_values_fk_attributes_id" FOREIGN KEY ("attributes_id")
  REFERENCES "attributes" ("attributes_id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "cart_products" ADD CONSTRAINT "cart_products_fk_carts_id" FOREIGN KEY ("carts_id")
  REFERENCES "carts" ("carts_id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "cart_products" ADD CONSTRAINT "cart_products_fk_sku" FOREIGN KEY ("sku")
  REFERENCES "products" ("sku") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "carts" ADD CONSTRAINT "carts_fk_sessions_id" FOREIGN KEY ("sessions_id")
  REFERENCES "sessions" ("sessions_id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "carts" ADD CONSTRAINT "carts_fk_users_id" FOREIGN KEY ("users_id")
  REFERENCES "users" ("users_id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "inventories" ADD CONSTRAINT "inventories_fk_sku" FOREIGN KEY ("sku")
  REFERENCES "products" ("sku") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "media_displays" ADD CONSTRAINT "media_displays_fk_media_types_id" FOREIGN KEY ("media_types_id")
  REFERENCES "media_types" ("media_types_id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "media_products" ADD CONSTRAINT "media_products_fk_media_id" FOREIGN KEY ("media_id")
  REFERENCES "medias" ("media_id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "media_products" ADD CONSTRAINT "media_products_fk_sku" FOREIGN KEY ("sku")
  REFERENCES "products" ("sku") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "merchandising_attributes" ADD CONSTRAINT "merchandising_attributes_fk_merchandising_products_id" FOREIGN KEY ("merchandising_products_id")
  REFERENCES "merchandising_products" ("merchandising_products_id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "merchandising_products" ADD CONSTRAINT "merchandising_products_fk_sku" FOREIGN KEY ("sku")
  REFERENCES "products" ("sku") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "merchandising_products" ADD CONSTRAINT "merchandising_products_fk_sku_related" FOREIGN KEY ("sku_related")
  REFERENCES "products" ("sku") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "navigation_attribute_values" ADD CONSTRAINT "navigation_attribute_values_fk_attribute_values_id" FOREIGN KEY ("attribute_values_id")
  REFERENCES "attribute_values" ("attribute_values_id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "navigation_attribute_values" ADD CONSTRAINT "navigation_attribute_values_fk_navigation_attributes_id" FOREIGN KEY ("navigation_attributes_id")
  REFERENCES "navigation_attributes" ("navigation_attributes_id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "navigation_attributes" ADD CONSTRAINT "navigation_attributes_fk_attributes_id" FOREIGN KEY ("attributes_id")
  REFERENCES "attributes" ("attributes_id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "navigation_attributes" ADD CONSTRAINT "navigation_attributes_fk_navigation_id" FOREIGN KEY ("navigation_id")
  REFERENCES "navigations" ("navigation_id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "navigation_products" ADD CONSTRAINT "navigation_products_fk_navigation_id" FOREIGN KEY ("navigation_id")
  REFERENCES "navigations" ("navigation_id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "navigation_products" ADD CONSTRAINT "navigation_products_fk_sku" FOREIGN KEY ("sku")
  REFERENCES "products" ("sku") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "navigations" ADD CONSTRAINT "navigations_fk_parent_id" FOREIGN KEY ("parent_id")
  REFERENCES "navigations" ("navigation_id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "orderlines" ADD CONSTRAINT "orderlines_fk_orders_id" FOREIGN KEY ("orders_id")
  REFERENCES "orders" ("orders_id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "orderlines" ADD CONSTRAINT "orderlines_fk_sku" FOREIGN KEY ("sku")
  REFERENCES "products" ("sku") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "permissions" ADD CONSTRAINT "permissions_fk_roles_id" FOREIGN KEY ("roles_id")
  REFERENCES "roles" ("roles_id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "price_modifiers" ADD CONSTRAINT "price_modifiers_fk_sku" FOREIGN KEY ("sku")
  REFERENCES "products" ("sku") DEFERRABLE;

;
ALTER TABLE "price_modifiers" ADD CONSTRAINT "price_modifiers_fk_roles_id" FOREIGN KEY ("roles_id")
  REFERENCES "roles" ("roles_id") DEFERRABLE;

;
ALTER TABLE "product_attribute_values" ADD CONSTRAINT "product_attribute_values_fk_attribute_values_id" FOREIGN KEY ("attribute_values_id")
  REFERENCES "attribute_values" ("attribute_values_id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "product_attribute_values" ADD CONSTRAINT "product_attribute_values_fk_product_attributes_id" FOREIGN KEY ("product_attributes_id")
  REFERENCES "product_attributes" ("product_attributes_id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "product_attributes" ADD CONSTRAINT "product_attributes_fk_attributes_id" FOREIGN KEY ("attributes_id")
  REFERENCES "attributes" ("attributes_id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "product_attributes" ADD CONSTRAINT "product_attributes_fk_sku" FOREIGN KEY ("sku")
  REFERENCES "products" ("sku") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "products" ADD CONSTRAINT "products_fk_canonical_sku" FOREIGN KEY ("canonical_sku")
  REFERENCES "products" ("sku") DEFERRABLE;

;
ALTER TABLE "shipment_destinations" ADD CONSTRAINT "shipment_destinations_fk_shipment_methods_id" FOREIGN KEY ("shipment_methods_id")
  REFERENCES "shipment_methods" ("shipment_methods_id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "shipment_destinations" ADD CONSTRAINT "shipment_destinations_fk_zones_id" FOREIGN KEY ("zones_id")
  REFERENCES "zones" ("zones_id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "shipment_methods" ADD CONSTRAINT "shipment_methods_fk_shipment_carriers_id" FOREIGN KEY ("shipment_carriers_id")
  REFERENCES "shipment_carriers" ("shipment_carriers_id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "shipment_rates" ADD CONSTRAINT "shipment_rates_fk_shipment_methods_id" FOREIGN KEY ("shipment_methods_id")
  REFERENCES "shipment_methods" ("shipment_methods_id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "shipment_rates" ADD CONSTRAINT "shipment_rates_fk_zones_id" FOREIGN KEY ("zones_id")
  REFERENCES "zones" ("zones_id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "shipments" ADD CONSTRAINT "shipments_fk_shipment_carriers_id" FOREIGN KEY ("shipment_carriers_id")
  REFERENCES "shipment_carriers" ("shipment_carriers_id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "shipments" ADD CONSTRAINT "shipments_fk_shipment_methods_id" FOREIGN KEY ("shipment_methods_id")
  REFERENCES "shipment_methods" ("shipment_methods_id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "states" ADD CONSTRAINT "states_fk_country_iso_code" FOREIGN KEY ("country_iso_code")
  REFERENCES "countries" ("country_iso_code") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "taxes" ADD CONSTRAINT "taxes_fk_country_iso_code" FOREIGN KEY ("country_iso_code")
  REFERENCES "countries" ("country_iso_code") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "taxes" ADD CONSTRAINT "taxes_fk_states_id" FOREIGN KEY ("states_id")
  REFERENCES "states" ("states_id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "user_attribute_values" ADD CONSTRAINT "user_attribute_values_fk_attribute_values_id" FOREIGN KEY ("attribute_values_id")
  REFERENCES "attribute_values" ("attribute_values_id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "user_attribute_values" ADD CONSTRAINT "user_attribute_values_fk_user_attributes_id" FOREIGN KEY ("user_attributes_id")
  REFERENCES "user_attributes" ("user_attributes_id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "user_attributes" ADD CONSTRAINT "user_attributes_fk_attributes_id" FOREIGN KEY ("attributes_id")
  REFERENCES "attributes" ("attributes_id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "user_attributes" ADD CONSTRAINT "user_attributes_fk_users_id" FOREIGN KEY ("users_id")
  REFERENCES "users" ("users_id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "zone_countries" ADD CONSTRAINT "zone_countries_fk_country_iso_code" FOREIGN KEY ("country_iso_code")
  REFERENCES "countries" ("country_iso_code") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "zone_countries" ADD CONSTRAINT "zone_countries_fk_zones_id" FOREIGN KEY ("zones_id")
  REFERENCES "zones" ("zones_id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "zone_states" ADD CONSTRAINT "zone_states_fk_states_id" FOREIGN KEY ("states_id")
  REFERENCES "states" ("states_id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "zone_states" ADD CONSTRAINT "zone_states_fk_zones_id" FOREIGN KEY ("zones_id")
  REFERENCES "zones" ("zones_id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "orders" ADD CONSTRAINT "orders_fk_billing_addresses_id" FOREIGN KEY ("billing_addresses_id")
  REFERENCES "addresses" ("addresses_id") DEFERRABLE;

;
ALTER TABLE "orders" ADD CONSTRAINT "orders_fk_shipping_addresses_id" FOREIGN KEY ("shipping_addresses_id")
  REFERENCES "addresses" ("addresses_id") DEFERRABLE;

;
ALTER TABLE "orders" ADD CONSTRAINT "orders_fk_users_id" FOREIGN KEY ("users_id")
  REFERENCES "users" ("users_id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "payment_orders" ADD CONSTRAINT "payment_orders_fk_orders_id" FOREIGN KEY ("orders_id")
  REFERENCES "orders" ("orders_id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "payment_orders" ADD CONSTRAINT "payment_orders_fk_sessions_id" FOREIGN KEY ("sessions_id")
  REFERENCES "sessions" ("sessions_id") ON DELETE SET NULL DEFERRABLE;

;
ALTER TABLE "payment_orders" ADD CONSTRAINT "payment_orders_fk_users_id" FOREIGN KEY ("users_id")
  REFERENCES "users" ("users_id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "users" ADD CONSTRAINT "users_fk_media_id" FOREIGN KEY ("media_id")
  REFERENCES "medias" ("media_id") DEFERRABLE;

;
ALTER TABLE "conference_tickets" ADD CONSTRAINT "conference_tickets_fk_conferences_id" FOREIGN KEY ("conferences_id")
  REFERENCES "conferences" ("conferences_id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "conference_tickets" ADD CONSTRAINT "conference_tickets_fk_sku" FOREIGN KEY ("sku")
  REFERENCES "products" ("sku") ON DELETE CASCADE DEFERRABLE;

;
ALTER TABLE "medias" ADD CONSTRAINT "medias_fk_author_users_id" FOREIGN KEY ("author_users_id")
  REFERENCES "users" ("users_id") DEFERRABLE;

;
ALTER TABLE "medias" ADD CONSTRAINT "medias_fk_media_types_id" FOREIGN KEY ("media_types_id")
  REFERENCES "media_types" ("media_types_id") ON DELETE CASCADE ON UPDATE CASCADE;

;
ALTER TABLE "order_statuses" ADD CONSTRAINT "order_statuses_fk_orders_id" FOREIGN KEY ("orders_id")
  REFERENCES "orders" ("orders_id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "user_roles" ADD CONSTRAINT "user_roles_fk_roles_id" FOREIGN KEY ("roles_id")
  REFERENCES "roles" ("roles_id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "user_roles" ADD CONSTRAINT "user_roles_fk_users_id" FOREIGN KEY ("users_id")
  REFERENCES "users" ("users_id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "conference_attendees" ADD CONSTRAINT "conference_attendees_fk_conferences_id" FOREIGN KEY ("conferences_id")
  REFERENCES "conferences" ("conferences_id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "conference_attendees" ADD CONSTRAINT "conference_attendees_fk_users_id" FOREIGN KEY ("users_id")
  REFERENCES "users" ("users_id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "messages" ADD CONSTRAINT "messages_fk_parent_id" FOREIGN KEY ("parent_id")
  REFERENCES "messages" ("messages_id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "messages" ADD CONSTRAINT "messages_fk_approved_by_users_id" FOREIGN KEY ("approved_by_users_id")
  REFERENCES "users" ("users_id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "messages" ADD CONSTRAINT "messages_fk_author_users_id" FOREIGN KEY ("author_users_id")
  REFERENCES "users" ("users_id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "messages" ADD CONSTRAINT "messages_fk_message_types_id" FOREIGN KEY ("message_types_id")
  REFERENCES "message_types" ("message_types_id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "orderlines_shippings" ADD CONSTRAINT "orderlines_shippings_fk_addresses_id" FOREIGN KEY ("addresses_id")
  REFERENCES "addresses" ("addresses_id") DEFERRABLE;

;
ALTER TABLE "orderlines_shippings" ADD CONSTRAINT "orderlines_shippings_fk_orderlines_id" FOREIGN KEY ("orderlines_id")
  REFERENCES "orderlines" ("orderlines_id") DEFERRABLE;

;
ALTER TABLE "orderlines_shippings" ADD CONSTRAINT "orderlines_shippings_fk_shipments_id" FOREIGN KEY ("shipments_id")
  REFERENCES "shipments" ("shipments_id") DEFERRABLE;

;
ALTER TABLE "talks" ADD CONSTRAINT "talks_fk_author_id" FOREIGN KEY ("author_id")
  REFERENCES "users" ("users_id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "talks" ADD CONSTRAINT "talks_fk_conferences_id" FOREIGN KEY ("conferences_id")
  REFERENCES "conferences" ("conferences_id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "attendee_talks" ADD CONSTRAINT "attendee_talks_fk_talks_id" FOREIGN KEY ("talks_id")
  REFERENCES "talks" ("talks_id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "attendee_talks" ADD CONSTRAINT "attendee_talks_fk_users_id" FOREIGN KEY ("users_id")
  REFERENCES "users" ("users_id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "product_reviews" ADD CONSTRAINT "product_reviews_fk_messages_id" FOREIGN KEY ("messages_id")
  REFERENCES "messages" ("messages_id") ON DELETE CASCADE DEFERRABLE;

;
ALTER TABLE "product_reviews" ADD CONSTRAINT "product_reviews_fk_sku" FOREIGN KEY ("sku")
  REFERENCES "products" ("sku") ON DELETE CASCADE DEFERRABLE;

;
ALTER TABLE "order_comments" ADD CONSTRAINT "order_comments_fk_messages_id" FOREIGN KEY ("messages_id")
  REFERENCES "messages" ("messages_id") ON DELETE CASCADE DEFERRABLE;

;
ALTER TABLE "order_comments" ADD CONSTRAINT "order_comments_fk_orders_id" FOREIGN KEY ("orders_id")
  REFERENCES "orders" ("orders_id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
