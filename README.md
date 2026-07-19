# Invoice Generator App

A Flutter application developed for creating, managing, and exporting invoices. This project demonstrates core Flutter concepts including state management, navigation, form validation, local database persistence using SQLite, multi-template PDF generation, device sharing/printing, and custom dashboard analytics.

---

## 📱 Features

### Core Features
- **Create Invoice**: Form workflow with input validation for required fields.
- **Auto Invoice Numbering**: Configurable prefix (e.g., `INV-`) with auto-incrementing serial numbers (e.g., `INV-001`).
- **Date Pickers**: Select Invoice Date and Due Date.
- **Business Information**: Company Name, Address, Email, Phone Number, and Logo.
- **Customer Information**: Select from saved Customer History or enter Customer Name, Address, Email, and Phone Number.
- **Multiple Line Items**: Product/Service Name, Quantity, Unit Price, and Discount (%).
- **Automatic Calculations**: Real-time calculation of Subtotal, Discount, Tax Amount, and Grand Total.
- **Notes & Payment Instructions**: Add payment terms and details.
- **Local Database**: Offline persistence powered by SQLite (`sqflite`).

### Invoice Management
- **Dashboard**: Overview cards for Total Invoices, Total Revenue, Paid, Unpaid, and Overdue amounts.
- **Invoice List & Search**: Search invoices by invoice number or customer name, with filter tabs (`All`, `Paid`, `Unpaid`, `Overdue`).
- **CRUD Operations**: View, Edit, Duplicate, and Delete invoices (with confirmation dialog).
- **Status Badges**: Mark invoices as `Paid`, `Unpaid`, or `Overdue`.

### Export & Sharing
- **PDF Generation**: High-resolution PDF generation with embedded company logo and payment QR code.
- **PDF Templates**: Choose between Classic, Modern, and Minimal template designs.
- **Print & Share**: Print directly or share PDF files via WhatsApp, Email, etc.

### Bonus Features
- 🌙 **Dark Mode**: Toggle between Light and Dark themes.
- 📷 **Company Logo Upload**: Select logo from gallery to include on invoices and PDFs.
- 📱 **Payment QR Code**: Dynamic QR code on screen and inside PDF.
- 👥 **Customer Catalog**: Manage client history and favorite customers.
- 📦 **Product Catalog**: Library of pre-saved products and services.
- 📊 **Monthly Income Summary**: Visual revenue breakdown chart on the Dashboard.
- 💾 **Backup & Restore**: Export complete data as a JSON file.
- 📤 **CSV Export**: Export invoice list as CSV.

---

## 🛠️ Packages Used

| Package | Purpose |
| :--- | :--- |
| `sqflite` / `sqflite_common_ffi` | Local SQLite database persistence |
| `pdf` | PDF document generation |
| `printing` | PDF preview, printing, and file sharing |
| `share_plus` | Device sharing integration |
| `image_picker` | Selecting company logo image |
| `intl` | Date and currency formatting |
| `uuid` | Unique ID generation |
| `qr_flutter` | Payment QR code rendering |
| `csv` | Exporting invoice reports as CSV |
| `path_provider` | Directory path management |

---

## 🚀 Setup & Build Instructions

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`>=3.12.0`)
- Android Studio / VS Code with Flutter plugin

### Running the App

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/SaadAyazCS/Invoice-Generator-App.git
   cd Invoice-Generator-App
   ```

2. **Install Dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run Application**:
   ```bash
   flutter run
   ```

4. **Build APK**:
   ```bash
   flutter build apk --release
   ```
