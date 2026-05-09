import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:media_store_plus/media_store_plus.dart';
import '../models/user_model.dart';
import '../models/plot_model.dart';
import '../models/installment_model.dart';

/// Service for generating professional bank challan PDFs.
///
/// Layout strategy (A4 landscape-ish triple copy):
/// ─────────────────────────────────────────────────
/// Page padding = 20 on every side.
/// Usable width on A4 portrait = 595.28 - 40 = 555.28 pt.
/// 3 columns × 170 pt + 2 gaps × 12 pt = 534 pt  ✓ fits.
///
/// Inside each column every text lives inside a pw.Table with
/// FIXED column widths so nothing can ever overflow or overlap.
class ChallanPdfService {
  // ── Design tokens ──────────────────────────────────────────────
  static final PdfColor _royalBlue = PdfColor.fromHex('#0050FF');
  static final PdfColor _lightBlue = PdfColor.fromHex('#E8F0FF');

  /// Width of a single challan copy column.
  static const double _colWidth = 170;

  /// Gap between the three columns.
  static const double _colGap = 12;

  /// Vertical gap between rows / sections.
  static const double _rowGap = 6;

  /// Page margin on all four sides.
  static const double _pagePad = 20;

  /// Label column inside a data table.
  static const double _labelW = 55;

  /// Value column = remaining space after label + inner padding.
  static const double _valueW = _colWidth - _labelW - 18; // 18 = cell paddings

  /// Standard body font size.
  static const double _bodyFs = 7;

  /// Standard bold font size for labels.
  static const double _labelFs = 7;

  // ── Public API ─────────────────────────────────────────────────

  /// Generate bank challan PDF with triple-copy layout and return saved [File].
  static Future<File?> generateChallanPdf({
    required UserModel user,
    required PlotModel plot,
    required InstallmentModel installment,
    required double amount,
    String? accountNumber,
    String? bankName = 'Royal Nest Bank',
    String? accountTitle = 'Royal Nest Properties (Pvt) Ltd',
    String? bankId = '',
    String? iban = 'PK93ABCD0123456789012345',
  }) async {
    try {
      final pdf = pw.Document();
      final challanId = _generateChallanId(user.uid);
      final now = DateTime.now();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(_pagePad),
          build: (pw.Context ctx) {
            return pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildCopy(
                  label: 'CUSTOMER COPY',
                  challanId: challanId,
                  now: now,
                  user: user,
                  plot: plot,
                  installment: installment,
                  amount: amount,
                  accountNumber: accountNumber ?? 'N/A',
                  bankName: bankName ?? 'Royal Nest Bank',
                  accountTitle:
                      accountTitle ?? 'Royal Nest Properties (Pvt) Ltd',
                  bankId: bankId ?? '',
                  iban: iban ?? 'PK93ABCD0123456789012345',
                ),
                pw.SizedBox(width: _colGap),
                _buildCopy(
                  label: 'OFFICE COPY',
                  challanId: challanId,
                  now: now,
                  user: user,
                  plot: plot,
                  installment: installment,
                  amount: amount,
                  accountNumber: accountNumber ?? 'N/A',
                  bankName: bankName ?? 'Royal Nest Bank',
                  accountTitle:
                      accountTitle ?? 'Royal Nest Properties (Pvt) Ltd',
                  bankId: bankId ?? '',
                  iban: iban ?? 'PK93ABCD0123456789012345',
                ),
                pw.SizedBox(width: _colGap),
                _buildCopy(
                  label: 'BANK COPY',
                  challanId: challanId,
                  now: now,
                  user: user,
                  plot: plot,
                  installment: installment,
                  amount: amount,
                  accountNumber: accountNumber ?? 'N/A',
                  bankName: bankName ?? 'Royal Nest Bank',
                  accountTitle:
                      accountTitle ?? 'Royal Nest Properties (Pvt) Ltd',
                  bankId: bankId ?? '',
                  iban: iban ?? 'PK93ABCD0123456789012345',
                ),
              ],
            );
          },
        ),
      );

      return await _savePdfFile(pdf, challanId, user.uid);
    } catch (e) {
      debugPrint('Error generating challan PDF: $e');
      return null;
    }
  }

  // ── Single challan copy ────────────────────────────────────────

  static pw.Widget _buildCopy({
    required String label,
    required String challanId,
    required DateTime now,
    required UserModel user,
    required PlotModel plot,
    required InstallmentModel installment,
    required double amount,
    required String accountNumber,
    required String bankName,
    required String accountTitle,
    required String bankId,
    required String iban,
  }) {
    final instNo =
        installment.totalInstallments - installment.upcomingInstallments;

    final rows = <List<String>>[
      ['Voucher ID', challanId],
      ['Date', DateFormat('dd/MM/yyyy').format(now)],
      ['Time', DateFormat('HH:mm').format(now)],
      ['Customer', _safe(user.username)],
      ['CNIC', _safe(user.cnic)],
      ['Phone', _safe(user.phone ?? '')],
      ['Email', _safe(user.email)],
      ['Society', _safe(plot.society)],
      ['Plot Title', _safe(plot.title)],
      ['Plot No', _safe(plot.plotNumber)],
      ['Block', _safe(plot.blockName)],
      ['Type', _safe(plot.plotType)],
      ['Size', _safe(plot.size)],
      ['Location', _safe(plot.location)],
      ['Price', _currency(plot.price)],
      ['Installment', '#$instNo'],
      ['Purpose', 'Installment Fee'],
      ['Amount', 'PKR ${amount.toStringAsFixed(0)}'],
      ['Bank', _safe(bankName)],
      ['Title', _safe(accountTitle)],
      ['Account', _safe(accountNumber)],
      if (bankId.isNotEmpty) ['Bank ID', _safe(bankId)],
      ['IBAN', _safe(iban)],
    ];

    return pw.SizedBox(
      width: _colWidth,
      child: pw.Container(
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: _royalBlue, width: 1),
          color: PdfColors.white,
        ),
        padding: const pw.EdgeInsets.all(6),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          mainAxisSize: pw.MainAxisSize.min,
          children: [
            // ── Header ──
            _buildHeader(label),
            pw.SizedBox(height: _rowGap),

            // ── Data table ──
            _buildDataTable(rows),
            pw.SizedBox(height: _rowGap),

            // ── Instructions ──
            _buildInstructions(),
            pw.SizedBox(height: _rowGap),

            // ── Signature ──
            _buildSignature(),
          ],
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────

  static pw.Widget _buildHeader(String copyLabel) {
    const innerW = _colWidth - 12; // 6 padding × 2
    return pw.Container(
      width: innerW,
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      decoration: pw.BoxDecoration(
        color: _royalBlue,
        borderRadius: pw.BorderRadius.circular(3),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: innerW - 12,
            child: pw.Text(
              'ROYAL NEST',
              style: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              maxLines: 1,
              softWrap: true,
              overflow: pw.TextOverflow.clip,
            ),
          ),
          pw.SizedBox(height: 2),
          pw.SizedBox(
            width: innerW - 12,
            child: pw.Text(
              'PAYMENT CHALLAN',
              style: pw.TextStyle(
                fontSize: 7,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              maxLines: 1,
              softWrap: true,
              overflow: pw.TextOverflow.clip,
            ),
          ),
          pw.SizedBox(height: 2),
          pw.SizedBox(
            width: innerW - 12,
            child: pw.Text(
              copyLabel,
              style: pw.TextStyle(
                fontSize: 6,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              maxLines: 1,
              softWrap: true,
              overflow: pw.TextOverflow.clip,
            ),
          ),
        ],
      ),
    );
  }

  // ── Data table (fixed-width columns, NO flexible / expanded) ──

  static pw.Widget _buildDataTable(List<List<String>> rows) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.3),
      columnWidths: {
        0: const pw.FixedColumnWidth(_labelW),
        1: const pw.FixedColumnWidth(_valueW),
      },
      children: List.generate(rows.length, (i) {
        final r = rows[i];
        return pw.TableRow(
          decoration: pw.BoxDecoration(
            color: i.isEven ? PdfColors.white : PdfColors.grey100,
          ),
          children: [
            // Label cell
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(
                vertical: 2,
                horizontal: 3,
              ),
              child: pw.ConstrainedBox(
                constraints: const pw.BoxConstraints(
                  maxWidth: _labelW - 6,
                  minHeight: 12,
                ),
                child: pw.Text(
                  r[0],
                  style: pw.TextStyle(
                    fontSize: _labelFs,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  maxLines: 2,
                  softWrap: true,
                  overflow: pw.TextOverflow.clip,
                ),
              ),
            ),
            // Value cell
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(
                vertical: 2,
                horizontal: 3,
              ),
              child: pw.ConstrainedBox(
                constraints: const pw.BoxConstraints(
                  maxWidth: _valueW - 6,
                  minHeight: 12,
                ),
                child: pw.Text(
                  r[1],
                  style: pw.TextStyle(fontSize: _bodyFs),
                  maxLines: 2,
                  softWrap: true,
                  overflow: pw.TextOverflow.clip,
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  // ── Instructions ───────────────────────────────────────────────

  static pw.Widget _buildInstructions() {
    const innerW = _colWidth - 12;
    return pw.Container(
      width: innerW,
      padding: const pw.EdgeInsets.all(4),
      decoration: pw.BoxDecoration(
        color: _lightBlue,
        borderRadius: pw.BorderRadius.circular(3),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: innerW - 8,
            child: pw.Text(
              'INSTRUCTIONS:',
              style: pw.TextStyle(
                fontSize: 6,
                fontWeight: pw.FontWeight.bold,
              ),
              maxLines: 1,
              softWrap: true,
            ),
          ),
          pw.SizedBox(height: 2),
          _instructionLine('1. Verify details before payment.'),
          _instructionLine('2. Use only for selected installment.'),
          _instructionLine('3. Keep receipt for your records.'),
        ],
      ),
    );
  }

  static pw.Widget _instructionLine(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 1),
      child: pw.SizedBox(
        width: _colWidth - 20,
        child: pw.Text(
          text,
          style: pw.TextStyle(fontSize: 6),
          maxLines: 2,
          softWrap: true,
          overflow: pw.TextOverflow.clip,
        ),
      ),
    );
  }

  // ── Signature ──────────────────────────────────────────────────

  static pw.Widget _buildSignature() {
    const innerW = _colWidth - 12;
    return pw.SizedBox(
      width: innerW,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: innerW,
            child: pw.Text(
              'Authorized Signature',
              style: pw.TextStyle(
                fontSize: 6,
                fontWeight: pw.FontWeight.bold,
              ),
              maxLines: 1,
              softWrap: true,
            ),
          ),
          pw.SizedBox(height: 14),
          pw.Container(width: 40, height: 0.8, color: PdfColors.black),
          pw.SizedBox(height: 2),
          pw.SizedBox(
            width: innerW,
            child: pw.Text(
              'Bank Officer',
              style: pw.TextStyle(fontSize: 6),
              maxLines: 1,
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────

  static String _safe(String v) => v.trim().isEmpty ? 'N/A' : v.trim();

  static String _currency(double v) => 'PKR ${v.toStringAsFixed(0)}';

  static String _generateChallanId(String userId) {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final code = userId.substring(0, 3).toUpperCase();
    final rand = (ts % 10000).toString().padLeft(4, '0');
    return 'CH-$code-$rand';
  }

  // ── File save (unchanged logic) ────────────────────────────────

  static Future<File?> _savePdfFile(
    pw.Document pdf,
    String challanId,
    String userId,
  ) async {
    try {
      debugPrint('📁 Saving PDF to public Downloads...');

      final timestamp = DateTime.now().toString().replaceAll(
        RegExp(r'[^\d]'),
        '',
      );
      final fileName = 'Challan_${userId}_$timestamp.pdf';

      final pdfBytes = await pdf.save();
      debugPrint('📊 PDF size: ${pdfBytes.length} bytes');

      // Android: save into the public Downloads folder using MediaStore.
      if (Platform.isAndroid) {
        try {
          MediaStore.appFolder = 'RoyalNest';
          await MediaStore.ensureInitialized();

          final tempDir = await getTemporaryDirectory();
          final tempFile = File('${tempDir.path}/$fileName');
          await tempFile.writeAsBytes(pdfBytes);

          final mediaStore = MediaStore();
          final saveInfo = await mediaStore.saveFile(
            tempFilePath: tempFile.path,
            dirType: DirType.download,
            dirName: DirName.download,
            relativePath: FilePath.root,
          );

          debugPrint('📦 MediaStore save result: $saveInfo');

          if (saveInfo != null) {
            final publicPath = '/storage/emulated/0/Download/${saveInfo.name}';
            final publicFile = File(publicPath);

            if (await publicFile.exists()) {
              debugPrint('✅ File saved to public Downloads: $publicPath');
              debugPrint('🔗 Public file Uri: ${saveInfo.uri}');
              return publicFile;
            }

            debugPrint(
              '⚠️ MediaStore reported success, but file path was not readable: $publicPath',
            );
            return File(publicPath);
          }

          debugPrint(
            '⚠️ MediaStore returned null, falling back to app storage',
          );
        } catch (e) {
          debugPrint('⚠️ MediaStore save failed: $e');
        }
      }

      // Last resort: App documents folder
      try {
        debugPrint('📁 Using app documents folder as last resort...');
        final appDocs = await getApplicationDocumentsDirectory();
        final filePath = '${appDocs.path}/$fileName';
        final file = File(filePath);
        await file.writeAsBytes(pdfBytes);

        if (await file.exists()) {
          debugPrint('✅ File saved to app documents: $filePath');
          debugPrint(
            '⚠️ NOTE: File is in app folder - please move to Downloads manually',
          );
          return file;
        }
      } catch (e) {
        debugPrint('❌ App documents save failed: $e');
      }

      debugPrint('❌ All save methods failed');
      return null;
    } catch (e, stackTrace) {
      debugPrint('❌ Error saving PDF: $e');
      debugPrint('📍 Stack trace: $stackTrace');
      return null;
    }
  }
}
