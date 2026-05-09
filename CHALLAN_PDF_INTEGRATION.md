# Bank Challan PDF Generator - Integration Guide

## 📋 Overview

This is a professional bank challan PDF generator for Royal Nest Flutter app. It creates realistic, printable 3-copy bank challans (Bank Copy, Company Copy, Customer Copy) with proper formatting and alignment for manual payment collection.

---

## 🎯 Features

✅ **Professional Bank-Style Layout**
- Triple copy design (A4 size)
- Print-friendly formatting
- Clean borders and dividers
- Realistic bank challan appearance

✅ **Complete Information**
- Unique auto-generated Challan IDs
- Customer details (Name, CNIC, Phone, Email)
- Property details (Plot, Project, Location)
- Payment details (Installment no, Amount, Purpose)
- Bank account information
- Signature sections

✅ **Seamless Integration**
- Firebase Firestore storage for challan records
- Download management
- Status tracking (pending, downloaded, deposited)
- Challan history tracking

✅ **User-Friendly**
- Single button download
- Success/error notifications
- Loading indicators
- Visual feedback

---

## 📁 File Structure

```
lib/
├── services/
│   ├── challan_pdf_service.dart          # PDF generation logic
│   └── document_service.dart             # Firestore & challan management
├── models/
│   └── challan_model.dart                # Challan data model
├── widgets/
│   └── challan_download_widget.dart      # UI components for challan
└── screens/
    └── challan_payment_screen.dart       # Example payment screen
```

---

## 🚀 Quick Start

### 1. **Basic Usage - Simple Widget Integration**

```dart
import 'package:fyp_royalnest/widgets/challan_download_widget.dart';

// In your payment screen/widget:
ChallanDownloadWidget(
  user: currentUser,           // UserModel
  plot: selectedPlot,          // PlotModel
  installment: paymentInfo,    // InstallmentModel
  amount: 10000.0,             // double
  bankName: 'Royal Nest Bank',
  accountNumber: '12345-67890-1',
  iban: 'PK93ABCD0123456789012345',
  onSuccess: () {
    print('Challan downloaded!');
  },
  onError: (error) {
    print('Error: $error');
  },
)
```

### 2. **Full Screen Integration**

```dart
import 'package:fyp_royalnest/screens/challan_payment_screen.dart';

// Navigate to payment screen:
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (context) => ChallanPaymentScreen(
      user: currentUser,
      plot: selectedPlot,
      installment: installmentData,
      amount: 10000.0,
    ),
  ),
);
```

---

## 🔧 API Reference

### **ChallanPdfService**

Main service for PDF generation.

#### `generateChallanPdf()`
Generates a PDF with 3 copies of the challan.

```dart
static Future<File?> generateChallanPdf({
  required UserModel user,
  required PlotModel plot,
  required InstallmentModel installment,
  required double amount,
  String? accountNumber,
  String? bankName = 'Royal Nest Bank',
  String? accountTitle = 'Royal Nest Properties (Pvt) Ltd',
  String? iban = 'PK93ABCD0123456789012345',
})
```

**Returns:** `File?` - The generated PDF file or null if failed

---

### **DocumentService** (Extended)

Enhanced with challan methods.

#### `generateAndDownloadChallan()`
Generates PDF and stores record in Firestore.

```dart
Future<Map<String, dynamic>> generateAndDownloadChallan({
  required UserModel user,
  required PlotModel plot,
  required InstallmentModel installment,
  required double amount,
  String? accountNumber,
  String? bankName,
  String? accountTitle,
  String? iban,
})
```

**Returns:** 
```dart
{
  'success': bool,
  'message': String,
  'filePath': String?,       // Local file path
  'fileName': String?,       // Generated filename
  'challanId': String?,      // Unique challan ID
}
```

#### `getUserChallanHistory()`
Get stream of challan records for a user.

```dart
Stream<List<ChallanModel>> getUserChallanHistory(String userId)
```

#### `getLatestChallan()`
Get the most recent challan for user and property.

```dart
Future<ChallanModel?> getLatestChallan(String userId, String propertyId)
```

#### `updateChallanStatus()`
Update challan status (downloaded, deposited, etc).

```dart
Future<bool> updateChallanStatus(
  String challanId,
  String newStatus,
  {DateTime? depositedAt}
)
```

#### `isChallanGenerated()`
Check if challan exists for specific installment.

```dart
Future<bool> isChallanGenerated(
  String userId,
  String propertyId,
  int installmentNumber
)
```

---

## 📊 Data Models

### **ChallanModel**

Represents a challan record in Firestore.

```dart
class ChallanModel {
  final String id;                    // Firestore doc ID
  final String challanId;             // Unique challan ID (CH-ABC-1234)
  final String userId;
  final String userName;
  final String userEmail;
  final String userCnic;
  final String userPhone;
  final String propertyId;
  final String propertyName;
  final String plotNumber;
  final String blockName;
  final int installmentNumber;
  final double amount;
  final String purpose;
  final String bankName;
  final String accountNumber;
  final String iban;
  final String status;                // pending, downloaded, deposited
  final DateTime generatedAt;
  final DateTime? downloadedAt;
  final DateTime? depositedAt;
}
```

---

## 💾 Database Schema

### Firestore Collection: `challans`

```json
{
  "challan_id": "CH-ABC-1234",
  "user_id": "user123",
  "user_name": "John Doe",
  "user_email": "john@example.com",
  "user_cnic": "12345-6789012-3",
  "user_phone": "+923001234567",
  "property_id": "prop456",
  "property_name": "Royal Nest",
  "plot_number": "101",
  "block_name": "A",
  "installment_number": 3,
  "amount": 10000.0,
  "purpose": "Installment Fee",
  "bank_name": "Royal Nest Bank",
  "account_number": "12345-67890-1",
  "iban": "PK93ABCD0123456789012345",
  "status": "downloaded",
  "generated_at": "2024-05-02T10:30:00Z",
  "downloaded_at": "2024-05-02T10:30:00Z",
  "deposited_at": null
}
```

---

## 🎨 PDF Layout Details

### Page Structure
- **A4 Size** (210mm × 297mm)
- **3 Sections** (one per copy)
- **Section Height**: ~99mm each
- **Margins**: 0 (full bleed)

### Each Copy Contains

#### 1. **Header Section**
```
┌─────────────────────────────────┐
│ ROYAL NEST │ PAYMENT CHALLAN │ 🏦 │
│ Deposit in any branch. Keep copy for record. │
│ [BANK COPY / COMPANY COPY / CUSTOMER COPY]  │
└─────────────────────────────────┘
```

#### 2. **Reference Info**
```
Challan No: CH-ABC-1234    Date: 02/05/2024
                           Time: 10:30 AM
```

#### 3. **Customer Information**
```
Name: John Doe
CNIC: 12345-6789012-3
Phone: +923001234567
Email: john@example.com
```

#### 4. **Property Details**
```
Project: Royal Nest
Plot No: 101 - Block A
Size: 10 Marla
Location: Lahore
```

#### 5. **Payment Details (Table)**
```
┌──────────────┬─────────────────┐
│ Field        │ Value           │
├──────────────┼─────────────────┤
│ Installment  │ #3 of 10        │
│ Purpose      │ Installment Fee │
│ Amount       │ PKR 10,000      │
└──────────────┴─────────────────┘
```

#### 6. **Bank Details**
```
Bank Name: Royal Nest Bank
Account Title: Royal Nest Properties (Pvt) Ltd
Account Number: 12345-67890-1
IBAN: PK93ABCD0123456789012345
```

#### 7. **Signature Section**
```
_____________    _____________    _____________
Officer Sign     Cashier Sign     Customer Sign
```

#### 8. **Footer**
```
💰 CASH ONLY
For bank use only - Deposit immediately on receipt
```

---

## 🔄 Integration Flow

### Scenario: User Wants to Pay Manually

```
1. User clicks "Pay Manually" button
   ↓
2. App shows ChallanDownloadWidget
   ↓
3. User clicks "Download Challan PDF"
   ↓
4. ChallanPdfService generates PDF
   ├─ Creates 3-copy layout
   ├─ Fills user/property/payment info
   ├─ Generates unique Challan ID
   └─ Saves to device
   ↓
5. FileSaver saves to Documents folder
   ↓
6. DocumentService stores record in Firestore
   ├─ Collection: "challans"
   ├─ Status: "downloaded"
   └─ Timestamp: DateTime.now()
   ↓
7. Show success notification
   ↓
8. User prints and submits to bank
   ↓
9. (Optional) User updates status to "deposited"
```

---

## ✅ Validation & Error Handling

The system validates:

- ✓ All required user fields exist
- ✓ Property information is complete
- ✓ Installment amount is valid
- ✓ PDF generation succeeds
- ✓ File save succeeds
- ✓ Firestore record created

**Error Handling:**
- PDF generation failures → User-friendly message
- File save failures → Error notification
- Firestore errors → Logged but doesn't block PDF delivery
- Missing fields → Default values applied

---

## 🎯 Status Tracking

Challan statuses in Firestore:

| Status | Meaning | Set When |
|--------|---------|----------|
| `pending` | Challan generated but not downloaded | Initial state |
| `downloaded` | User downloaded the PDF | After PDF generation |
| `deposited` | User confirmed deposit at bank | Manual update by user |

### Update Status Example:

```dart
await documentService.updateChallanStatus(
  'challanDocId',
  'deposited',
  depositedAt: DateTime.now(),
);
```

---

## 📱 File Management

### Download Location

**Android/iOS:**
- Saved to app documents directory
- User can access via file manager
- Filename format: `Challan_<userId>_<timestamp>.pdf`

**Example:**
```
/storage/emulated/0/Documents/Challan_user123_20240502103000.pdf
```

### File Naming Convention

```
Challan_<userId>_<timestamp>.pdf

Example: Challan_user123_20240502103000123456.pdf
```

---

## 🔒 Security Considerations

1. **Firestore Rules** - Restrict challan access to own user:
```
match /challans/{document=**} {
  allow read: if request.auth.uid == resource.data.user_id;
  allow create: if request.auth.uid == request.resource.data.user_id;
}
```

2. **PDF Contains Sensitive Data** - Handle appropriately
3. **Local File Access** - Secured by Android/iOS permissions
4. **Timestamps** - Use server timestamps for accountability

---

## 🧪 Testing

### Manual Test Scenario:

```dart
void testChallanGeneration() async {
  final user = UserModel(
    uid: 'test-user-123',
    username: 'Test User',
    email: 'test@example.com',
    cnic: '12345-6789012-3',
    role: 'client',
  );

  final plot = PlotModel(
    id: 'plot-123',
    title: 'Test Plot',
    society: 'Royal Nest',
    size: '10 Marla',
    plotNumber: '101',
    blockName: 'A',
    plotType: 'Residential',
    price: 1000000,
    location: 'Lahore',
    description: 'Test',
  );

  final installment = InstallmentModel(
    id: 'inst-123',
    paymentId: 'pay-123',
    userId: 'test-user-123',
    userName: 'Test User',
    propertyId: 'plot-123',
    propertyName: 'Royal Nest',
    totalInstallments: 10,
    paidInstallments: 2,
    currentInstallmentAmount: 10000.0,
  );

  final result = await documentService.generateAndDownloadChallan(
    user: user,
    plot: plot,
    installment: installment,
    amount: 10000.0,
  );

  expect(result['success'], true);
  expect(result['filePath'], isNotNull);
  expect(result['challanId'], isNotNull);
}
```

---

## 🐛 Troubleshooting

### Issue: PDF not generating
**Solution:** 
- Check if all required fields are provided
- Ensure `intl` package is in pubspec.yaml
- Check device storage space

### Issue: File not saving
**Solution:**
- Check Android/iOS permissions
- Ensure sufficient storage
- Check app has file write permissions

### Issue: Firestore record not created
**Solution:**
- Check Firestore rules allow write
- Verify user is authenticated
- Check network connectivity

### Issue: Challan not downloading
**Solution:**
- Check FileSaver permissions
- Try on physical device (simulator may have issues)
- Check available storage

---

## 📚 Dependencies

```yaml
pdf: ^3.11.1              # PDF generation
printing: ^5.13.4         # Print support
path_provider: ^2.1.5     # Local file path
file_saver: ^0.2.14       # Save files
intl: ^0.19.0             # Date formatting
cloud_firestore: ^5.6.12  # Database
```

---

## 🎓 Example Usage in Existing Payment Screen

If you already have a payment screen, add this:

```dart
// In your payment screen
import 'package:fyp_royalnest/widgets/challan_download_widget.dart';

@override
Widget build(BuildContext context) {
  return Scaffold(
    body: SingleChildScrollView(
      child: Column(
        children: [
          // Your existing UI
          Text('Total: PKR ${amount.toStringAsFixed(0)}'),
          
          // Add challan download section
          if (paymentMethod == 'manual')
            Padding(
              padding: EdgeInsets.all(16),
              child: ChallanDownloadWidget(
                user: currentUser,
                plot: selectedPlot,
                installment: installmentData,
                amount: amount,
              ),
            ),
        ],
      ),
    ),
  );
}
```

---

## ✨ Advanced Features

### 1. **Challan History**

Show all challans generated by user:

```dart
StreamBuilder<List<ChallanModel>>(
  stream: documentService.getUserChallanHistory(userId),
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      return ListView(
        children: snapshot.data!
            .map((challan) => ListTile(
              title: Text('Challan #${challan.challanId}'),
              subtitle: Text('Status: ${challan.status}'),
            ))
            .toList(),
      );
    }
    return CircularProgressIndicator();
  },
)
```

### 2. **Check if Challan Exists**

```dart
final exists = await documentService.isChallanGenerated(
  userId,
  propertyId,
  installmentNumber,
);

if (!exists) {
  // Show download button
}
```

### 3. **Get Challan Statistics**

```dart
final count = await documentService.getUserChallanCount(userId);
print('Total challans generated: $count');
```

---

## 📞 Support

For issues or questions:
1. Check Firestore permissions
2. Verify all required fields are populated
3. Check device storage and permissions
4. Review Firebase Console for errors

---

## 📝 License

This challan PDF system is part of Royal Nest project.

**Last Updated:** May 2, 2026
**Version:** 1.0.0
