# 👟 StepUp – Smart Footwear E-Commerce Platform

[![Flutter Version](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Dart Version](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)](https://dart.dev)
[![Backend](https://img.shields.io/badge/Backend-Google%20Sheets%20API-34A853?logo=googlesheets)](https://developers.google.com/apps-script)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

StepUp is a high-performance cross-platform footwear e-commerce application designed for sneakerheads and streetwear enthusiasts. Built with **Flutter** and powered by a serverless **Google Sheets** cloud database via **Google Apps Script**, it delivers a full-featured e-commerce ecosystem at zero backend hosting cost.

---

## ✨ Features

### 🛍️ Customer Experience
* **Live Discovery & Feed:** Curated "Season Drops", daily flash deals, best-seller lists, and dynamic brand searches.
* **Automatic Geolocation:** Auto-detects deliverable address via IP-level geolocation with clean fallbacks.
* **Smart Catalog & Filter Engine:** Multi-parameter search by brand (Nike, Puma, Adidas, StepUp, Reebok, etc.), shoe size (UK 6–11), color, and maximum price ceiling.
* **Interactive Reviews:** Real-time customer ratings and feedback stored directly in the cloud database.
* **Cart & Wishlist:** Multi-session persistence with instant item migration between wishlist and shopping bag.
* **Secure Dual Checkout:**
  * **Cash on Delivery (COD)**
  * **Instant UPI Pay:** Integrated transfer with verification for 12-digit bank UTR / Reference numbers.
* **Live Shipment Stepper:** Real-time 4-stage tracking timeline (`Pending` ➔ `Accepted` ➔ `Dispatched` ➔ `Delivered`).
* **Automated PDF Billing:** Generates and downloads official GST-compliant Tax Invoices on device with a single tap.

### 🛡️ Admin Dashboard & Control Panel
* **Live Analytics:** Parallel data fetching displaying live users, active products, placed orders, and total revenue.
* **Zero-Dependency Canvas Charts:**
  * **Payment Split Chart:** Visual donut breakdown of UPI vs. COD amounts.
  * **Fulfillment Chart:** Live order status breakdown.
* **Management Consoles:** Tools to add/delete products, manage orders, view user accounts, and inspect payment audits.
* **Admin Profile:** Dedicated control page showcasing admin credentials, company info, and cloud synchronization health.

---

## 🛠️ Technology Stack

| Domain | Technology / Service |
|---|---|
| **Mobile Frontend** | Flutter & Dart |
| **Backend & Database** | Google Sheets & Google Apps Script REST API |
| **Document Generation**| `pdf` & `printing` packages (`InvoiceService`) |
| **Networking** | Dart `http` with asynchronous `Future.wait` |
| **Geolocation** | Dual fallback via `ipwho.is` and `ipapi.co` |

---

## 🚀 Getting Started

### Prerequisites
* [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.10 or higher)
* [Dart SDK](https://dart.dev/get-dart)
* Android Studio or VS Code with Flutter extension
* An active Google account (for Google Sheets API backend)

### Installation

1. **Clone the repository:**
   
```bash
   git clone [https://github.com/](https://github.com/)<your-username>/stepup-footwear-app.git
   cd stepup-footwear-app

lib/
├── admin/
│   ├── admin_dashboard.dart       # Main admin console with custom charts
│   ├── admin_profile_screen.dart  # Super admin credentials and status
│   ├── admin_products_screen.dart # Inventory management
│   ├── admin_orders_screen.dart   # Order processing
│   ├── admin_users_screen.dart    # User directory
│   ├── admin_payments_screen.dart # Financial audit
│   └── admin_reviews_screen.dart  # Customer feedback moderation
├── api_service.dart               # REST communication with Google Sheets
├── invoice_service.dart           # PDF invoice generator
├── index.dart                     # Discovery feed & home screen
├── shop.dart                      # Shoe catalog, filtering, & checkout modal
├── cart.dart                      # Cart management screen
├── wishlist.dart                  # Bookmarked footwear view
├── track_order.dart               # Order timeline stepper & bill download
├── notifications_screen.dart      # Live push-style updates & bill links
├── profile.dart                   # Customer membership dashboard
└── main.dart                      # App entry point & theme configurations
