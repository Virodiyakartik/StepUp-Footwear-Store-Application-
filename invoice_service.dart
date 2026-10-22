import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class InvoiceService {
  static Future<void> generateAndDownloadInvoice({
    required String orderId,
    required String date,
    required String customerName,
    required String customerEmail,
    required String customerPhone,
    required String customerAddress,
    required String paymentMethod,
    required List<Map<String, dynamic>> items,
    required int subtotal,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'STEPUP FOOTWEAR',
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text('Official Store Invoice', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                      pw.Text('GSTIN: 24AAACS1234F1Z5', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('TAX INVOICE', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                      pw.SizedBox(height: 4),
                      pw.Text('Order #: $orderId', style: const pw.TextStyle(fontSize: 10)),
                      pw.Text('Date: $date', style: const pw.TextStyle(fontSize: 10)),
                      pw.Text('Payment Mode: $paymentMethod', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ],
              ),
              pw.Divider(thickness: 1.5, color: PdfColors.grey400, height: 24),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('CUSTOMER & SHIPPING DETAILS:', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 4),
                      pw.Text(customerName, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Email: $customerEmail', style: const pw.TextStyle(fontSize: 10)),
                      pw.Text('Phone: +91 $customerPhone', style: const pw.TextStyle(fontSize: 10)),
                      pw.SizedBox(height: 2),
                      pw.Container(
                        width: 250,
                        child: pw.Text('Address: $customerAddress', style: const pw.TextStyle(fontSize: 10)),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('STATUS', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 2),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.green100,
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: pw.Text('PAID / CONFIRMED', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.green900)),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                columnWidths: {
                  0: const pw.FlexColumnWidth(3.5),
                  1: const pw.FlexColumnWidth(1.5),
                  2: const pw.FlexColumnWidth(1.2),
                  3: const pw.FlexColumnWidth(1.0),
                  4: const pw.FlexColumnWidth(1.5),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      _cell('ITEM & TITLE', isHeader: true),
                      _cell('BRAND / COLOR', isHeader: true),
                      _cell('SIZE', isHeader: true, align: pw.TextAlign.center),
                      _cell('QTY', isHeader: true, align: pw.TextAlign.center),
                      _cell('PRICE', isHeader: true, align: pw.TextAlign.right),
                    ],
                  ),
                  ...items.map((item) {
                    final title = (item['title'] ?? item['shoe_name'] ?? 'Shoe').toString();
                    final brand = (item['brand'] ?? 'StepUp').toString();
                    final color = (item['color'] ?? 'Black').toString();
                    final size = (item['selected_size'] ?? item['size'] ?? '7').toString();
                    final qty = (item['quantity'] as num?)?.toInt() ?? 1;
                    final price = (item['price'] as num?)?.toInt() ?? 0;
                    return pw.TableRow(
                      children: [
                        _cell(title),
                        _cell('$brand ($color)'),
                        _cell('UK $size', align: pw.TextAlign.center),
                        _cell('$qty', align: pw.TextAlign.center),
                        _cell('Rs. ${price * qty}', align: pw.TextAlign.right),
                      ],
                    );
                  }).toList(),
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Container(
                    width: 220,
                    child: pw.Column(
                      children: [
                        _summaryRow('Subtotal:', 'Rs. $subtotal'),
                        _summaryRow('Delivery:', 'FREE'),
                        _summaryRow('GST (18% included):', 'Rs. ${(subtotal * 0.18).toInt()}'),
                        pw.Divider(thickness: 1, color: PdfColors.grey400),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Grand Total:', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                            pw.Text('Rs. $subtotal', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.Spacer(),
              pw.Divider(thickness: 0.5, color: PdfColors.grey300),
              pw.SizedBox(height: 4),
              pw.Center(
                child: pw.Text(
                  'Thank you for shopping with StepUp Footwear!',
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'StepUp_Invoice_$orderId.pdf',
    );
  }

  static pw.Widget _cell(String text, {bool isHeader = false, pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: isHeader ? 9.5 : 9,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  static pw.Widget _summaryRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 9.5, color: PdfColors.grey700)),
          pw.Text(value, style: const pw.TextStyle(fontSize: 9.5)),
        ],
      ),
    );
  }
}