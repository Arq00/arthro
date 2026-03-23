// lib/views/report/widgets/pdf_preview_sheet.dart
//
// REQUIRED — add to pubspec.yaml:
//   pdf: ^3.11.0
//   printing: ^5.13.0
//
// `printing` handles everything cross-platform:
//   • Android/iOS  →  Printing.layoutPdf()  opens system Save-to-Files/Downloads dialog
//   • Share sheet  →  Printing.sharePdf()   opens native share / AirDrop
//   No path_provider or manual file I/O needed.

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../models/report_model.dart';
import 'package:arthro/widgets/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PUBLIC ENTRY-POINT
// ─────────────────────────────────────────────────────────────────────────────
class DoctorReportSheet extends StatelessWidget {
  final PdfReportData data;
  const DoctorReportSheet({super.key, required this.data});

  static void show(BuildContext context, PdfReportData data) {
    showModalBottomSheet(
      context:            context,
      isScrollControlled: true,
      backgroundColor:    Colors.transparent,
      builder: (_) => DoctorReportSheet(data: data),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      maxChildSize:     0.96,
      minChildSize:     0.6,
      builder: (_, scroll) => Container(
        decoration: const BoxDecoration(
          color:        AppColors.bgCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // ── Drag handle ───────────────────────────────────────────────
            Container(
              width: 36, height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color:        AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // ── Header bar ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 16, 10),
              child: Row(children: [
                const Text('📄', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Clinical Report',
                      style: AppTextStyles.sectionTitle()),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      color:  AppColors.bgSection,
                      shape:  BoxShape.circle,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Icon(Icons.close,
                        size: 14, color: AppColors.textSecondary),
                  ),
                ),
              ]),
            ),
            const Divider(height: 1),

            // ── Scrollable preview ────────────────────────────────────────
            Expanded(
              child: ListView(
                controller: scroll,
                padding: const EdgeInsets.all(16),
                children: [
                  _Letterhead(data: data),
                  const SizedBox(height: 16),
                  _KpiGrid(data: data),
                  const SizedBox(height: 16),
                  if (data.flareDates.isNotEmpty) ...[
                    _FlareBanner(dates: data.flareDates),
                    const SizedBox(height: 16),
                  ],
                  _SecLabel('JOINT PAIN DISTRIBUTION'),
                  _JointPieChart(jointScores: data.jointAvgScores),
                  const SizedBox(height: 16),
                  _SecLabel('MEDICATION ADHERENCE'),
                  _MedTable(data: data),
                  if (data.medAdherence < 90) ...[
                    const SizedBox(height: 8),
                    _AlertBar(
                      color:   AppColors.tierHigh,
                      bgColor: AppColors.tierHighBg,
                      text:
                          '⚠️ ${data.flareDays} flare days recorded — review adherence gaps',
                    ),
                  ],
                  const SizedBox(height: 16),
                  _EularBox(data: data),
                  const SizedBox(height: 16),
                  _SecLabel('ACTION ITEMS FOR NEXT VISIT'),
                  _ActionList(items: data.actionItems),
                  const SizedBox(height: 20),
                  _SignatureRow(),
                  const SizedBox(height: 12),
                ],
              ),
            ),

            // ── Bottom action bar (stateful for loading spinner) ──────────
            _BottomBar(data: data),
          ],
        ),
      ),
    );
  }
}

// Backward-compat alias
typedef PdfPreviewSheet = DoctorReportSheet;

// ─────────────────────────────────────────────────────────────────────────────
// BOTTOM BAR  — Download + Share
// ─────────────────────────────────────────────────────────────────────────────
class _BottomBar extends StatefulWidget {
  final PdfReportData data;
  const _BottomBar({required this.data});

  @override
  State<_BottomBar> createState() => _BottomBarState();
}

class _BottomBarState extends State<_BottomBar> {
  bool _busy = false;

  // ── PDF builder ───────────────────────────────────────────────────────────
  Future<Uint8List> _buildPdfBytes() async {
    final d = widget.data;

    // Shared colour constants (PdfColor)
    const teal  = PdfColor.fromInt(0xFF1B5F5F);
    const red   = PdfColor.fromInt(0xFFD32F2F);
    const amber = PdfColor.fromInt(0xFFF9A825);
    const green = PdfColor.fromInt(0xFF388E3C);
    const grey  = PdfColor.fromInt(0xFF9E9E9E);
    const bgGr  = PdfColor.fromInt(0xFFF5F5F5);
    const white = PdfColors.white;
    const black = PdfColor.fromInt(0xFF212121);

    PdfColor tierCol(String t) {
      switch (t) {
        case 'REMISSION': return green;
        case 'LOW':       return amber;
        case 'MODERATE':  return PdfColor.fromInt(0xFFEF6C00);
        default:          return red;
      }
    }

    // Text styles
    final captSt = pw.TextStyle(fontSize: 8,  color: grey);
    final bodySt = pw.TextStyle(fontSize: 9,  color: black);
    final boldSt = pw.TextStyle(fontSize: 9,  color: black, fontWeight: pw.FontWeight.bold);
    final secSt  = pw.TextStyle(fontSize: 8,  color: grey,  fontWeight: pw.FontWeight.bold, letterSpacing: 1.2);

    String fmtD(DateTime dt) {
      const mo = ['','Jan','Feb','Mar','Apr','May','Jun',
                   'Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${dt.day} ${mo[dt.month]} ${dt.year}';
    }

    final doc = pw.Document(
      title:   'ArthroCare Report — ${d.patientName}',
      author:  'ArthroCare',
      creator: 'ArthroCare',
    );

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin:     const pw.EdgeInsets.all(32),

      // ── Running header ──────────────────────────────────────────────────
      header: (_) => pw.Container(
        padding: const pw.EdgeInsets.only(bottom: 8),
        decoration: const pw.BoxDecoration(
          border: pw.Border(
            bottom: pw.BorderSide(color: teal, width: 2))),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [

        
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
              pw.Text('RA TRACKING REPORT',
                  style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold,
                      color: teal, letterSpacing: 1)),
              pw.Text('${fmtD(d.periodFrom)} – ${fmtD(d.periodTo)}', style: captSt),
              pw.Text('Generated: ${fmtD(DateTime.now())}', style: captSt),
            ]),
          ],
        ),
      ),

      // ── Running footer ──────────────────────────────────────────────────
      footer: (ctx) => pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('ArthroCare — Confidential Medical Document', style: captSt),
          pw.Text('Page ${ctx.pageNumber} of ${ctx.pagesCount}',  style: captSt),
        ],
      ),

      // ── Body ─────────────────────────────────────────────────────────────
      build: (ctx) => [

        // 1. KPI row
        pw.Row(children: [
          _pKpi('RAPID3 Avg',   d.avgRapid3.toStringAsFixed(1),  tierCol(d.avgTier)),
          _pKpi('Flare Days',   '${d.flareDays}',                red),
          _pKpi('Med Adherence','${d.medAdherence.round()}%',     green),
          _pKpi('Best Score',   d.bestScore.toStringAsFixed(1),   green),
        ]),
        pw.SizedBox(height: 14),

        // 2. Flare dates (if any)
        if (d.flareDates.isNotEmpty) ...[
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color:  const PdfColor.fromInt(0xFFFFEBEE),
              border: pw.Border.all(color: red, width: 0.5),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Row(children: [
              pw.Text('⚠  Flare dates: ',
                  style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: red)),
              pw.Text(d.flareDates.map(fmtD).join('  ·  '),
                  style: pw.TextStyle(fontSize: 9, color: red)),
            ]),
          ),
          pw.SizedBox(height: 12),
        ],

        // 3. Joint distribution (bar chart)
        pw.Text('JOINT PAIN DISTRIBUTION', style: secSt),
        pw.SizedBox(height: 6),
        _pJointBars(d.jointAvgScores, bodySt, captSt, bgGr, teal),
        pw.SizedBox(height: 14),

        // 4. Medication adherence
        pw.Text('MEDICATION ADHERENCE', style: secSt),
        pw.SizedBox(height: 6),
        _pMedTable(d.medItems, bodySt, captSt, boldSt, bgGr, green, amber, red),
        pw.SizedBox(height: 14),

        // 5. EULAR response
        pw.Text('EULAR/ACR TREATMENT RESPONSE', style: secSt),
        pw.SizedBox(height: 6),
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color:  const PdfColor.fromInt(0xFFF1F8E9),
            border: pw.Border.all(color: green, width: 0.5),
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text(d.eularResponse,
                style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: green)),
            pw.SizedBox(height: 4),
            pw.Text(
              'Baseline RAPID3: ${d.baselineRapid3.toStringAsFixed(1)}  →  '
              'Current avg: ${d.avgRapid3.toStringAsFixed(1)}  '
              '(Δ ${(d.avgRapid3 - d.baselineRapid3) >= 0 ? "+" : ""}'
              '${(d.avgRapid3 - d.baselineRapid3).toStringAsFixed(1)})',
              style: bodySt,
            ),
          ]),
        ),
        pw.SizedBox(height: 14),

        // 6. Action items
        pw.Text('ACTION ITEMS FOR NEXT VISIT', style: secSt),
        pw.SizedBox(height: 6),
        ...d.actionItems.asMap().entries.map((e) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 5),
          child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Container(
              width: 18, height: 18,
              alignment: pw.Alignment.center,
              decoration: const pw.BoxDecoration(color: teal, shape: pw.BoxShape.circle),
              child: pw.Text('${e.key + 1}',
                  style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: white)),
            ),
            pw.SizedBox(width: 8),
            pw.Expanded(child: pw.Text(e.value, style: bodySt)),
          ]),
        )),

        pw.SizedBox(height: 24),

        // 7. Signature line
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          _pSignBox('Physician Signature', captSt),
          _pSignBox('Date', captSt),
        ]),
      ],
    ));

    return doc.save();
  }

  // ── PDF sub-widgets ────────────────────────────────────────────────────────

  static pw.Widget _pKpi(String label, String value, PdfColor col) =>
      pw.Expanded(
        child: pw.Container(
          margin:  const pw.EdgeInsets.only(right: 6),
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: pw.BoxDecoration(
            color:        const PdfColor.fromInt(0xFFF5F5F5),
            borderRadius: pw.BorderRadius.circular(4),
            border:       pw.Border.all(
                color: const PdfColor.fromInt(0xFFE0E0E0), width: 0.5),
          ),
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text(value,
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: col)),
            pw.Text(label,
                style: const pw.TextStyle(
                    fontSize: 8, color: PdfColor.fromInt(0xFF9E9E9E))),
          ]),
        ),
      );

  static pw.Widget _pJointBars(
    Map<String, double> scores,
    pw.TextStyle body, pw.TextStyle capt,
    PdfColor bg, PdfColor accent,
  ) {
    if (scores.isEmpty) return pw.Text('No joint data recorded.', style: capt);
    final sorted = (scores.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).take(6).toList();
    final maxV = sorted.first.value;
    return pw.Column(
      children: sorted.map((e) {
        final pct  = maxV > 0 ? e.value / maxV : 0.0;
        final name = e.key.replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m.group(0)}').trim();
        return pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 5),
          child: pw.Row(children: [
            pw.SizedBox(width: 130, child: pw.Text(name, style: body)),
            pw.Expanded(
              child: pw.Container(
                height: 8,
                decoration: pw.BoxDecoration(
                    color: bg, borderRadius: pw.BorderRadius.circular(4)),
                child: pw.Row(children: [
                  pw.Expanded(
                    flex: (pct.clamp(0.02, 1.0) * 100).round(),
                    child: pw.Container(
                      decoration: pw.BoxDecoration(
                          color: accent,
                          borderRadius: pw.BorderRadius.circular(4)),
                    ),
                  ),
                  pw.Expanded(
                    flex: ((1.0 - pct.clamp(0.02, 1.0)) * 100).round().clamp(0, 98),
                    child: pw.SizedBox(),
                  ),
                ]),
              ),
            ),
            pw.SizedBox(width: 8),
            pw.Text(e.value.toStringAsFixed(1), style: body),
          ]),
        );
      }).toList(),
    );
  }

  static pw.Widget _pMedTable(
    List<MedAdherenceItem> items,
    pw.TextStyle body, pw.TextStyle capt, pw.TextStyle bold,
    PdfColor bg, PdfColor green, PdfColor amber, PdfColor red,
  ) {
    PdfColor col(double pct) => pct >= 90 ? green : pct >= 70 ? amber : red;
    return pw.Table(
      border:       pw.TableBorder.all(color: const PdfColor.fromInt(0xFFE0E0E0), width: 0.5),
      columnWidths: const {0: pw.FlexColumnWidth(2), 1: pw.FlexColumnWidth(1), 2: pw.FlexColumnWidth(3)},
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFF5F5F5)),
          children: [
            _pTh('Medication', bold), _pTh('Adherence', bold), _pTh('Progress', bold),
          ],
        ),
        ...items.map((m) => pw.TableRow(children: [
          pw.Padding(padding: const pw.EdgeInsets.all(8),
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text(m.medName, style: bold),
              pw.Text(m.dosage,  style: capt),
            ])),
          pw.Padding(padding: const pw.EdgeInsets.all(8),
            child: pw.Text('${m.adherencePct.round()}%',
                style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold,
                    color: col(m.adherencePct)))),
          pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 14),
            child: pw.Container(
              height: 7,
              decoration: pw.BoxDecoration(
                  color: const PdfColor.fromInt(0xFFEEEEEE),
                  borderRadius: pw.BorderRadius.circular(4)),
              child: pw.Row(children: [
                pw.Expanded(
                  flex: (m.adherencePct.clamp(2.0, 100.0)).round(),
                  child: pw.Container(
                    decoration: pw.BoxDecoration(
                        color: col(m.adherencePct),
                        borderRadius: pw.BorderRadius.circular(4)),
                  ),
                ),
                pw.Expanded(
                  flex: (100 - m.adherencePct.clamp(2.0, 100.0)).round().clamp(0, 98),
                  child: pw.SizedBox(),
                ),
              ]),
            )),
        ])),
      ],
    );
  }

  static pw.Widget _pTh(String t, pw.TextStyle s) =>
      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(t, style: s));

  static pw.Widget _pSignBox(String label, pw.TextStyle capt) =>
      pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Container(width: 160, height: 0.5,
            color: const PdfColor.fromInt(0xFF9E9E9E)),
        pw.SizedBox(height: 4),
        pw.Text(label, style: capt),
      ]);

  // ── Filename helper ────────────────────────────────────────────────────────
  String get _filename =>
      'ArthroCare_${widget.data.patientName.replaceAll(' ', '_')}_'
      '${DateTime.now().millisecondsSinceEpoch}.pdf';

  // ── Download: confirm → generate → system save dialog ─────────────────────
  Future<void> _onDownload(BuildContext ctx) async {
    final confirmed = await showDialog<bool>(
      context: ctx,
      barrierDismissible: false,
      builder: (dlgCtx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg)),
        backgroundColor: AppColors.bgCard,
        contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
        titlePadding:   const EdgeInsets.fromLTRB(20, 20, 20, 8),
        title: Row(children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color:        AppColors.primarySurface,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: const Icon(Icons.download_rounded,
                color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Text('Download PDF', style: AppTextStyles.cardTitle()),
        ]),
        content: Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 20),
          child: Text(
            'Save a PDF copy of this clinical report to your device?\n\n'
            'Period: ${_fmtShort(widget.data.periodFrom)} – '
            '${_fmtShort(widget.data.periodTo)}',
            style: AppTextStyles.bodySmall()
                .copyWith(color: AppColors.textMuted, height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dlgCtx, false),
            style: TextButton.styleFrom(
                foregroundColor: AppColors.textMuted),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(dlgCtx, true),
            icon:  const Icon(Icons.download_rounded, size: 16),
            label: const Text('Download'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation:       0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm)),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    try {
      final bytes = await _buildPdfBytes();
      // layoutPdf() triggers the native Print/Save dialog.
      // On Android it saves to Downloads; on iOS it opens Files/AirDrop.
      await Printing.layoutPdf(
        onLayout: (_) async => bytes,
        name:     _filename,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:         Text('Could not generate PDF: $e'),
          backgroundColor: AppColors.tierHigh,
          behavior:        SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ── Share: generate → native share sheet ───────────────────────────────────
  Future<void> _onShare(BuildContext ctx) async {
    setState(() => _busy = true);
    try {
      final bytes = await _buildPdfBytes();
      await Printing.sharePdf(bytes: bytes, filename: _filename);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:         Text('Could not share PDF: $e'),
          backgroundColor: AppColors.tierHigh,
          behavior:        SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      decoration: BoxDecoration(
        color:  AppColors.bgCard,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Row(children: [

        // ── Download button ────────────────────────────────────────────────
        Expanded(
          child: GestureDetector(
            onTap: _busy ? null : () => _onDownload(context),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              height: 44,
              decoration: BoxDecoration(
                color:        _busy
                    ? AppColors.primary.withOpacity(0.5)
                    : AppColors.primary,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Center(
                child: _busy
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.download_rounded,
                            color: Colors.white, size: 18),
                        const SizedBox(width: 7),
                        Text('Download PDF',
                            style: AppTextStyles.buttonPrimary()
                                .copyWith(color: Colors.white)),
                      ]),
              ),
            ),
          ),
        ),

        const SizedBox(width: 10),

        // ── Share icon button ──────────────────────────────────────────────
        GestureDetector(
          onTap: _busy ? null : () => _onShare(context),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 44, height: 44,
            decoration: BoxDecoration(
              color:        _busy
                  ? AppColors.bgSection.withOpacity(0.5)
                  : AppColors.bgSection,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.border),
            ),
            child: Icon(Icons.share_rounded,
                size:  18,
                color: _busy
                    ? AppColors.primary.withOpacity(0.4)
                    : AppColors.primary),
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ALL EXISTING PREVIEW WIDGETS (unchanged)
// ─────────────────────────────────────────────────────────────────────────────

class _Letterhead extends StatelessWidget {
  final PdfReportData data;
  const _Letterhead({required this.data});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.base),
    decoration: BoxDecoration(
      color:        AppColors.bgSection,
      borderRadius: BorderRadius.circular(AppRadius.md),
      border:       Border(bottom: BorderSide(color: AppColors.primary, width: 2)),
    ),
    child: Row(children: [
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(data.patientName.toUpperCase(), style: AppTextStyles.sectionTitle()),
          Text('${data.patientGender}  ·  ${data.patientAge} yr',
              style: AppTextStyles.caption()),
          Text('Rheumatologist: ${data.doctorName}', style: AppTextStyles.caption()),
        ]),
      ),
      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text('RA TRACKING REPORT',
            style: AppTextStyles.labelCaps().copyWith(color: AppColors.primary)),
        Text('${_fmtShort(data.periodFrom)} – ${_fmtShort(data.periodTo)}',
            style: AppTextStyles.caption()),
      ]),
    ]),
  );
}

class _KpiGrid extends StatelessWidget {
  final PdfReportData data;
  const _KpiGrid({required this.data});
  @override
  Widget build(BuildContext context) {
    final tierColor = AppTierHelper.color(data.avgTier);
    final days      = data.periodTo.difference(data.periodFrom).inDays;
    return GridView.count(
      crossAxisCount: 2, shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 2.6,
      children: [
        _KpiBox(value: '${data.avgRapid3.toStringAsFixed(1)} ${AppTierHelper.emoji(data.avgTier)}',
            label: 'RAPID3 Avg ($days days)', color: tierColor),
        _KpiBox(value: '${data.flareDays}',
            label: 'Flare Days', color: AppColors.tierHigh),
        _KpiBox(value: '${data.medAdherence.round()}%',
            label: 'Med Adherence', color: AppColors.tierRemission),
        _KpiBox(value: '${data.bestScore.toStringAsFixed(1)} 🟢',
            label: 'Best Day Score', color: AppColors.tierRemission),
      ],
    );
  }
}

class _FlareBanner extends StatelessWidget {
  final List<DateTime> dates;
  const _FlareBanner({required this.dates});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color:        AppColors.tierHighBg,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      border:       Border.all(color: AppColors.tierHigh.withOpacity(0.3)),
    ),
    child: Row(children: [
      const Icon(Icons.warning_amber_rounded, color: AppColors.tierHigh, size: 18),
      const SizedBox(width: 8),
      Expanded(
        child: Text('Flares on: ${dates.map(_fmtShort).join(', ')}',
            style: AppTextStyles.bodySmall().copyWith(color: AppColors.tierHigh)),
      ),
    ]),
  );
}

class _JointPieChart extends StatelessWidget {
  final Map<String, double> jointScores;
  const _JointPieChart({required this.jointScores});
  @override
  Widget build(BuildContext context) {
    if (jointScores.isEmpty) {
      return Container(height: 60, alignment: Alignment.center,
          child: Text('No joint data recorded.', style: AppTextStyles.caption()));
    }
    final sorted = (jointScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value))).take(6).toList();
    final total = sorted.fold(0.0, (s, e) => s + e.value);
    const colours = [
      AppColors.tierHigh, AppColors.tierModerate, AppColors.tierLow,
      AppColors.tierRemission, AppColors.info, AppColors.primary,
    ];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:        AppColors.bgSection,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border:       Border.all(color: AppColors.border),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        SizedBox(width: 120, height: 120,
          child: CustomPaint(painter: _PiePainter(
            slices: sorted.asMap().entries.map((e) => _PieSlice(
              value: e.value.value, color: colours[e.key % colours.length])).toList()))),
        const SizedBox(width: 16),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: sorted.asMap().entries.map((e) {
              final color = colours[e.key % colours.length];
              final pct   = total > 0 ? (e.value.value / total * 100).round() : 0;
              final name  = e.value.key
                  .replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m.group(0)}').trim();
              return Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(children: [
                  Container(width: 10, height: 10,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
                  const SizedBox(width: 6),
                  Expanded(child: Text(name,
                      style: AppTextStyles.bodySmall(), overflow: TextOverflow.ellipsis)),
                  Text('$pct%',
                      style: AppTextStyles.labelCaps().copyWith(color: color)),
                ]),
              );
            }).toList()),
        ),
      ]),
    );
  }
}

class _PieSlice {
  final double value; final Color color;
  const _PieSlice({required this.value, required this.color});
}

class _PiePainter extends CustomPainter {
  final List<_PieSlice> slices;
  const _PiePainter({required this.slices});
  @override
  void paint(Canvas canvas, Size size) {
    if (slices.isEmpty) return;
    final total = slices.fold(0.0, (s, e) => s + e.value);
    if (total <= 0) return;
    final cx = size.width / 2, cy = size.height / 2;
    final r = math.min(cx, cy) - 6, ri = r * 0.42;
    double a = -math.pi / 2;
    for (final sl in slices) {
      final sw = (sl.value / total) * 2 * math.pi;
      final path = Path()
        ..moveTo(cx + ri * math.cos(a), cy + ri * math.sin(a))
        ..arcTo(Rect.fromCircle(center: Offset(cx, cy), radius: r),  a,       sw,  false)
        ..arcTo(Rect.fromCircle(center: Offset(cx, cy), radius: ri), a + sw, -sw, false)
        ..close();
      canvas.drawPath(path, Paint()..color = sl.color..style = PaintingStyle.fill);
      canvas.drawPath(path, Paint()..color = AppColors.bgCard
          ..style = PaintingStyle.stroke..strokeWidth = 1.5);
      a += sw;
    }
  }
  @override
  bool shouldRepaint(_PiePainter o) => o.slices != slices;
}

class _MedTable extends StatelessWidget {
  final PdfReportData data;
  const _MedTable({required this.data});
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadius.sm)),
    child: Column(children: data.medItems.asMap().entries.map((entry) {
      final m     = entry.value;
      final last  = entry.key == data.medItems.length - 1;
      final color = m.adherencePct >= 90 ? AppColors.tierRemission
          : m.adherencePct >= 70 ? AppColors.tierLow : AppColors.tierHigh;
      return Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(children: [
            SizedBox(width: 110, child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(m.medName, style: AppTextStyles.cardTitle()),
                Text(m.dosage,  style: AppTextStyles.caption()),
              ],
            )),
            Expanded(child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: m.adherencePct / 100, minHeight: 8,
                backgroundColor: AppColors.bgSection,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            )),
            const SizedBox(width: 8),
            Text('${m.adherencePct.round()}%',
                style: AppTextStyles.label().copyWith(color: color)),
          ]),
        ),
        if (!last) const Divider(height: 1),
      ]);
    }).toList()),
  );
}

class _EularBox extends StatelessWidget {
  final PdfReportData data;
  const _EularBox({required this.data});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.base),
    decoration: BoxDecoration(
      color:        AppColors.tierLowBg,
      borderRadius: BorderRadius.circular(AppRadius.md),
      border:       Border.all(color: AppColors.tierLow.withOpacity(0.3)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('EULAR/ACR TREATMENT RESPONSE', style: AppTextStyles.labelCaps()),
      const SizedBox(height: 6),
      Text(data.eularResponse,
          style: AppTextStyles.sectionTitle().copyWith(color: AppColors.tierLow)),
      const SizedBox(height: 4),
      Text(
        'Baseline RAPID3: ${data.baselineRapid3.toStringAsFixed(1)}  →  '
        'Current avg: ${data.avgRapid3.toStringAsFixed(1)}  '
        '(Δ ${(data.avgRapid3 - data.baselineRapid3) >= 0 ? '+' : ''}'
        '${(data.avgRapid3 - data.baselineRapid3).toStringAsFixed(1)})',
        style: AppTextStyles.caption(),
      ),
    ]),
  );
}

class _ActionList extends StatelessWidget {
  final List<String> items;
  const _ActionList({required this.items});
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadius.sm)),
    child: Column(children: items.asMap().entries.map((entry) {
      final last = entry.key == items.length - 1;
      return Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 22, height: 22, alignment: Alignment.center,
              decoration: const BoxDecoration(
                  color: AppColors.primary, shape: BoxShape.circle),
              child: Text('${entry.key + 1}', style: const TextStyle(
                  color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(entry.value, style: AppTextStyles.bodySmall())),
          ]),
        ),
        if (!last) const Divider(height: 1),
      ]);
    }).toList()),
  );
}

class _SignatureRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [_SignBlock(label: 'Physician Signature'), _SignBlock(label: 'Date')],
  );
}

class _SignBlock extends StatelessWidget {
  final String label;
  const _SignBlock({required this.label});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(width: 130, height: 1, color: AppColors.textMuted),
      const SizedBox(height: 4),
      Text(label, style: AppTextStyles.caption()),
    ],
  );
}

class _SecLabel extends StatelessWidget {
  final String text;
  const _SecLabel(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: AppTextStyles.labelCaps()),
  );
}

class _KpiBox extends StatelessWidget {
  final String value, label; final Color color;
  const _KpiBox({required this.value, required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
    decoration: BoxDecoration(
      color:        AppColors.bgSection,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      border:       Border.all(color: AppColors.border),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center, children: [
      Text(value, style: AppTextStyles.scoreMedium(color).copyWith(fontSize: 20)),
      Text(label,  style: AppTextStyles.caption()),
    ]),
  );
}

class _AlertBar extends StatelessWidget {
  final Color color, bgColor; final String text;
  const _AlertBar({required this.color, required this.bgColor, required this.text});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md, vertical: AppSpacing.sm),
    decoration: BoxDecoration(
      color:        bgColor,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      border:       Border.all(color: color.withOpacity(0.3)),
    ),
    child: Text(text,
        style: AppTextStyles.bodySmall()
            .copyWith(color: color, fontWeight: FontWeight.w600)),
  );
}

// ─── Helpers ──────────────────────────────────────────────────────────────────
String _fmtShort(DateTime d) {
  const m = ['','Jan','Feb','Mar','Apr','May','Jun',
              'Jul','Aug','Sep','Oct','Nov','Dec'];
  return '${d.day} ${m[d.month]} ${d.year}';
}