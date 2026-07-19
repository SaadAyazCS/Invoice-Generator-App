# 🧾 Invoice Master Pro - Flutter Invoice Generator App

[![Flutter](https://img.shields.io/badge/Flutter-3.29%2B-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.7%2B-0175C2?logo=dart)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

**Invoice Master Pro** is a feature-packed, production-grade Flutter application built to streamline invoice creation, management, export, and client cataloging. Built with modern **Material Design 3**, responsive layouts, local **SQLite** persistence, multi-template **PDF generation**, native sharing/printing, and analytics.

---

## 📱 Features

### ⚡ Core Features
- **Invoice Creation**: Fast, intuitive invoice creation workflow with complete form validation.
- **Auto Invoice Numbering**: Configurable prefix (e.g. `INV-`, `BILL-`) with auto-incrementing serial numbers (`INV-001`, `INV-002`).
- **Flexible Date Selection**: Select Invoice Date and Due Date using integrated calendar date pickers.
- **Business Profile**: Configure Company Name, Address, Email, Phone, Tax ID, and Company Logo.
- **Customer Information**: Save and select client details (Name, Address, Email, Phone) from built-in Customer History.
- **Dynamic Items & Services**: Add multiple products/services with quantity, unit price, and optional percentage discount per item.
- **Live Automatic Calculation**: Real-time computation of Subtotal, Discount Totals, Tax Amount, and Grand Total.
- **Notes & Payment Instructions**: Add terms, notes, and bank / UPI / PayPal payment details.
- **Local Persistence**: Full offline capability using SQLite database (`sqflite` & `sqflite_common_ffi`).

### 📊 Invoice Management
- **Interactive Dashboard**: Metrics cards for Total Invoices, Total Revenue, Paid, Unpaid, and Overdue amounts.
- **Visual Analytics**: Interactive 6-month revenue chart displaying monthly income breakdown.
- **Search & Filtering**: Real-time search by invoice number or customer name, with status tabs (`All`, `Paid`, `Unpaid`, `Overdue`).
- **CRUD Operations**: View, Edit, Duplicate, and Delete invoices (with confirmation dialog).
- **Status Lifecycle**: Toggle statuses between `Paid`, `Unpaid`, and `Overdue` (auto-detected when due date passes).

### 📄 Export & Sharing
- **PDF Generation Engine**: Instant high-resolution PDF generation with embedded company logo and payment QR code.
- **Multiple PDF Templates**: Choose between **Classic Elegant**, **Modern Indigo**, and **Minimal Monochrome** templates.
- **Download & View**: Offline PDF preview and download directly to the device.
- **Native Sharing**: Share PDF files via WhatsApp, Email, Drive, etc. (`share_plus`).
- **Direct Printing**: Native printer integration using `printing`.

### 🌙 Bonus Features Included
- 🌙 **Dark Mode Theme**: Persistent light and dark mode toggling.
- 📷 **Company Logo Upload**: Select company logo from gallery and embed directly into invoice headers and PDFs.
- 📱 **QR Code for Payment**: Generates dynamic QR code on screen and directly inside generated PDF for instant payment scanning.
- 👥 **Customer Catalog**: Manage client directory with favorite tags and 1-click selection.
- 📦 **Product Catalog**: Library of pre-saved products/services with default pricing for fast invoice assembly.
- 📈 **Monthly Revenue Chart**: Visual trend charts on the Dashboard.
- 💾 **Data Backup & Restore**: Export full database as a structured JSON backup file.
- 📤 **CSV Export**: Export full invoice register to CSV format.

---

## 🛠️ Packages Used

| Package | Version | Purpose |
| :--- | :--- | :--- |
| [`sqflite`](https://pub.dev/packages/sqflite) | `^2.4.1` | Local SQLite database for mobile |
| [`sqflite_common_ffi`](https://pub.dev/packages/sqflite_common_ffi) | `^2.3.4` | SQLite FFI engine for desktop platforms |
| [`pdf`](https://pub.dev/packages/pdf) | `^3.11.1` | High quality PDF document creation engine |
| [`printing`](https://pub.dev/packages/printing) | `^5.13.4` | PDF preview, printing, and sharing integration |
| [`share_plus`](https://pub.dev/packages/share_plus) | `^10.1.4` | Native device sharing (WhatsApp, Email, etc.) |
| [`image_picker`](https://pub.dev/packages/image_picker) | `^1.1.2` | Gallery image picker for company logo upload |
| [`intl`](https://pub.dev/packages/intl) | `^0.20.2` | Date and currency formatting |
| [`uuid`](https://pub.dev/packages/uuid) | `^4.5.1` | Unique ID generation |
| [`qr_flutter`](https://pub.dev/packages/qr_flutter) | `^4.1.0` | QR Code rendering for payment links |
| [`csv`](https://pub.dev/packages/csv) | `^6.0.0` | Exporting invoice reports as CSV |
| [`path_provider`](https://pub.dev/packages/path_provider) | `^2.1.5` | Accessing system documents/downloads directories |

---

## 🚀 Setup & Installation Instructions

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`>=3.12.0`)
- Android Studio / VS Code with Flutter extension
- JDK 17 / Android SDK API 34+

### Step-by-Step Run & Build Commands

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/your-username/invoice-generator-app.git
   cd invoice-generator-app
   ```

2. **Install Dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run the Application**:
   - For Android Emulator / Physical Device:
     ```bash
     flutter run
     ```
   - For Windows Desktop:
     ```bash
     flutter run -d windows
     ```
   - For Web Browser:
     ```bash
     flutter run -d chrome
     ```

4. **Build Release APK**:
   ```bash
   flutter build apk --release
   ```
   The generated APK will be located at:
   `build/app/outputs/flutter-apk/app-release.apk`

---

## 📸 Application Screenshots

Below are representations of the application's key screens:

| 1. Dashboard & Revenue Chart | 2. Invoice Management List |
| :---: | :---: |
| ![Dashboard](screenshots/dashboard.png) | ![Invoice List](screenshots/invoice_list.png) |

| 3. Create / Edit Invoice | 4. PDF Preview & Template Picker |
| :---: | :---: |
| ![Create Invoice](screenshots/create_invoice.png) | ![PDF Preview](screenshots/pdf_preview.png) |

| 5. Company & App Settings | 6. Customer Catalog |
| :---: | :---: |
| ![Settings](screenshots/settings.png) | ![Customer History](screenshots/customers.png) |

---

## 🤝 License

Distributed under the MIT License.
