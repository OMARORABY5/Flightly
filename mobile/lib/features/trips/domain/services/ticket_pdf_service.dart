import 'dart:typed_data';
import 'package:flightly/features/trips/domain/models/trip.dart';
import 'package:flightly/features/booking/domain/models/booking.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class TicketPdfService {
  // ─── Palette: navy-first, minimal accent ────────────────────────────────────
  static const _navy   = PdfColor.fromInt(0xFF1E3A5F);
  static const _blue   = PdfColor.fromInt(0xFF2F80ED);
  static const _steel  = PdfColor.fromInt(0xFF4A6FA5); // muted blue for return
  static const _green  = PdfColor.fromInt(0xFF27AE60);
  static const _red    = PdfColor.fromInt(0xFFEB5757);
  static const _orange = PdfColor.fromInt(0xFFF2994A);
  static const _light  = PdfColor.fromInt(0xFFF0F4F8);
  static const _border = PdfColor.fromInt(0xFFC8D8EE);
  static const _grey   = PdfColor.fromInt(0xFF6B7A99);

  // ─── Resolve ticket status from context ────────────────────────────────────
  /// Call this from the calling site to get the correct status string to pass
  /// into [generateAndShareTicket] / [generateForBooking].
  ///
  ///  - Booking confirmation → always 'confirmed'
  ///  - Upcoming trip        → 'confirmed'
  ///  - Completed trip       → 'flown'
  ///  - Cancelled trip       → 'cancelled'
  static String resolveForTrip(Trip trip) {
    if (trip.isCancelled) return 'cancelled';
    if (trip.isCompleted) return 'flown';
    return 'confirmed'; // upcoming
  }

  // ─── Public API ─────────────────────────────────────────────────────────────
  static Future<void> generateAndShareTicket(Trip trip) async {
    final oLogo = await _logo(trip.flight.airlineLogoUrl);
    final rLogo = trip.returnFlight != null ? await _logo(trip.returnFlight!.airlineLogoUrl) : null;
    final bytes = await _render(
      ref: trip.reference, isRT: trip.isRoundTrip,
      resolvedStatus: resolveForTrip(trip), created: trip.createdAt,
      oCode: trip.flight.originIata,      oCity: trip.flight.originCity ?? '',
      dCode: trip.flight.destinationIata, dCity: trip.flight.destinationCity ?? '',
      oDep: trip.flight.departureTime,    oArr: trip.flight.arrivalTime,
      oAir: trip.flight.airlineName,      oFlt: trip.flight.flightNumber,
      oDur: trip.flight.durationMinutes,  oLogo: oLogo,
      rCode: trip.returnFlight?.originIata,      rCity: trip.returnFlight?.originCity,
      r2Code: trip.returnFlight?.destinationIata, r2City: trip.returnFlight?.destinationCity,
      rDep: trip.returnFlight?.departureTime,     rArr: trip.returnFlight?.arrivalTime,
      rAir: trip.returnFlight?.airlineName,       rFlt: trip.returnFlight?.flightNumber,
      rDur: trip.returnFlight?.durationMinutes,   rLogo: rLogo,
      pax: trip.passengers, cabin: trip.cabinClass,
      paxCount: trip.passengerCount, total: trip.totalPrice,
    );
    if (bytes.isEmpty) throw Exception('PDF generation produced empty output');
    await _downloadBytes(bytes, 'Flightly_${trip.reference}.pdf');
  }

  static Future<void> generateForBooking(Booking booking) async {
    final oLogo = await _logo(booking.outboundFlight.airlineLogoUrl);
    final rLogo = booking.returnFlight != null ? await _logo(booking.returnFlight!.airlineLogoUrl) : null;
    final bytes = await _render(
      ref: booking.reference, isRT: booking.tripType == 'round_trip',
      resolvedStatus: 'confirmed', // Always confirmed right after payment
      created: booking.createdAt,
      oCode: booking.outboundFlight.originIata,      oCity: booking.outboundFlight.originCity ?? '',
      dCode: booking.outboundFlight.destinationIata, dCity: booking.outboundFlight.destinationCity ?? '',
      oDep: booking.outboundFlight.departureTime,    oArr: booking.outboundFlight.arrivalTime,
      oAir: booking.outboundFlight.airlineName,      oFlt: booking.outboundFlight.flightNumber,
      oDur: booking.outboundFlight.durationMinutes,  oLogo: oLogo,
      rCode: booking.returnFlight?.originIata,       rCity: booking.returnFlight?.originCity,
      r2Code: booking.returnFlight?.destinationIata, r2City: booking.returnFlight?.destinationCity,
      rDep: booking.returnFlight?.departureTime,     rArr: booking.returnFlight?.arrivalTime,
      rAir: booking.returnFlight?.airlineName,       rFlt: booking.returnFlight?.flightNumber,
      rDur: booking.returnFlight?.durationMinutes,   rLogo: rLogo,
      pax: booking.passengers.map((p) => p.fullName).toList(),
      cabin: booking.cabinClass, paxCount: booking.passengers.length, total: booking.totalPrice,
    );
    if (bytes.isEmpty) throw Exception('PDF generation produced empty output');
    await _downloadBytes(bytes, 'Flightly_${booking.reference}.pdf');
  }

  // ─── Web-safe download ──────────────────────────────────────────────────────────────
  // On web, Printing.sharePdf opens the browser print dialog which the user
  // must then manually save.  Instead, trigger a real file download via
  // a temporary <a> element so the PDF lands directly in Downloads.
  static Future<void> _downloadBytes(Uint8List bytes, String filename) async {
    final blob = html.Blob([bytes], 'application/pdf');
    final url  = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..style.display = 'none';
    html.document.body!.append(anchor);
    anchor.click();
    anchor.remove();
    html.Url.revokeObjectUrl(url);
  }

  // ─── Safe logo fetch ─────────────────────────────────────────────────────────────
  // networkImage() fails on web due to CORS and causes the entire PDF page
  // to corrupt.  We fetch manually and fall back to null gracefully.
  static Future<pw.ImageProvider?> _logo(String? url) async {
    if (url == null || url.trim().isEmpty) return null;
    try {
      final response = await http.get(Uri.parse(url))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        return pw.MemoryImage(response.bodyBytes);
      }
      return null;
    } catch (_) {
      return null; // Never let a logo failure break the PDF
    }
  }

  // ─── Core renderer — single pw.Page, no Expanded/Spacer ─────────────────────
  static Future<Uint8List> _render({
    required String ref, required bool isRT,
    required String resolvedStatus, required DateTime created,
    required String oCode, required String oCity,
    required String dCode, required String dCity,
    required DateTime oDep, required DateTime oArr,
    required String oAir, required String oFlt,
    required int oDur, pw.ImageProvider? oLogo,
    String? rCode, String? rCity, String? r2Code, String? r2City,
    DateTime? rDep, DateTime? rArr,
    String? rAir, String? rFlt, int? rDur, pw.ImageProvider? rLogo,
    required List<String> pax, required String cabin,
    required int paxCount, required double total,
  }) async {
    final badge  = _badge(resolvedStatus);
    final cabStr = _cabinLabel(cabin);
    final bag    = cabin.toLowerCase().contains('business') ? '32 kg' : '23 kg';

    final pdf = pw.Document();
    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.zero,
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────────
          _hdr(ref, badge),

          // ── Body ────────────────────────────────────────────────────────────
          pw.Padding(
            padding: const pw.EdgeInsets.fromLTRB(28, 18, 28, 0),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Outbound
                _card(
                  tag: isRT ? 'OUTBOUND FLIGHT' : 'FLIGHT ITINERARY',
                  color: _blue,
                  oCode: oCode, oCity: oCity, dCode: dCode, dCity: dCity,
                  dep: oDep, arr: oArr, air: oAir, flt: oFlt, dur: oDur,
                  cabin: cabStr, bag: bag, logo: oLogo,
                ),
                // Return
                if (isRT && rCode != null) ...[
                  pw.SizedBox(height: 6),
                  _divider(),
                  pw.SizedBox(height: 6),
                  _card(
                    tag: 'RETURN FLIGHT',
                    color: _steel,
                    oCode: rCode, oCity: rCity ?? '', dCode: r2Code ?? '', dCity: r2City ?? '',
                    dep: rDep!, arr: rArr!, air: rAir ?? '', flt: rFlt ?? '',
                    dur: rDur ?? 0, cabin: cabStr, bag: bag, logo: rLogo,
                  ),
                ],
                pw.SizedBox(height: 14),
                // Bottom row: passengers + summary left, QR right
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Left column
                    pw.Expanded(
                      flex: 3,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _paxBox(pax),
                          pw.SizedBox(height: 8),
                          _sumBox(isRT: isRT, count: paxCount, created: created, total: total, badge: badge),
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 12),
                    // Right column — QR
                    pw.Column(
                      children: [
                        pw.BarcodeWidget(data: ref, barcode: pw.Barcode.qrCode(), width: 140, height: 140,
                          decoration: pw.BoxDecoration(border: pw.Border.all(color: _border), borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6))),
                        ),
                        pw.SizedBox(height: 6),
                        pw.Text('Scan at check-in', style: pw.TextStyle(fontSize: 9, color: _grey)),
                        pw.SizedBox(height: 3),
                        pw.Text(ref, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _navy, letterSpacing: 1)),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 10),
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromInt(0xFFFFF0F0),
                    border: pw.Border.all(color: _red, width: 1),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      '! Electronic ticket  -  Please ensure all passport and travel documents are valid before flight.',
                      style: pw.TextStyle(fontSize: 10, color: _red, fontWeight: pw.FontWeight.bold),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                ),
                pw.SizedBox(height: 10),
              ],
            ),
          ),
        ],
      ),
    ));
    return pdf.save();
  }

  // ── Header bar ──────────────────────────────────────────────────────────────
  static pw.Widget _hdr(String ref, ({PdfColor color, String label}) badge) =>
    pw.Container(
      width: double.infinity,
      color: _navy,
      padding: const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 14),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text('FLIGHTLY', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
            pw.Text('E-TICKET', style: pw.TextStyle(fontSize: 8, color: PdfColor.fromInt(0xFF90B4D8), letterSpacing: 3)),
          ]),
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: pw.BoxDecoration(color: badge.color, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10))),
              child: pw.Text(badge.label, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
            ),
            pw.SizedBox(height: 4),
            pw.Text(ref, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.white, letterSpacing: 1.5)),
          ]),
        ],
      ),
    );

  // ── Flight Card ──────────────────────────────────────────────────────────────
  static pw.Widget _card({
    required String tag, required PdfColor color,
    required String oCode, required String oCity,
    required String dCode, required String dCity,
    required DateTime dep, required DateTime arr,
    required String air, required String flt,
    required int dur, required String cabin, required String bag,
    pw.ImageProvider? logo,
  }) {
    final h = dur ~/ 60, m = dur % 60;
    return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      // Tag bar
      pw.Container(
        color: color,
        width: double.infinity,
        padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: pw.Text(tag, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white, letterSpacing: 1.5)),
      ),
      // Body
      pw.Container(
        width: double.infinity,
        decoration: pw.BoxDecoration(
          border: pw.Border(
            left: pw.BorderSide(color: color, width: 3),
            right: pw.BorderSide(color: _border),
            bottom: pw.BorderSide(color: _border),
          ),
          color: PdfColors.white,
        ),
        padding: const pw.EdgeInsets.all(16),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          // Airline row
          pw.Row(children: [
            if (logo != null)
              pw.Container(width: 22, height: 22, child: pw.Image(logo, fit: pw.BoxFit.contain))
            else
              pw.Container(
                width: 28, height: 28,
                decoration: pw.BoxDecoration(color: _navy, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3))),
                child: pw.Center(child: pw.Text(air.isNotEmpty ? air[0] : '?', style: pw.TextStyle(color: PdfColors.white, fontSize: 13, fontWeight: pw.FontWeight.bold))),
              ),
            pw.SizedBox(width: 8),
            pw.Text(air, style: pw.TextStyle(fontSize: 12, color: _navy, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(width: 7),
            pw.Text(flt, style: pw.TextStyle(fontSize: 10, color: _grey)),
          ]),
          pw.SizedBox(height: 10),
          // Route
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text(oCode, style: pw.TextStyle(fontSize: 34, fontWeight: pw.FontWeight.bold, color: _navy)),
              pw.Text(oCity, style: pw.TextStyle(fontSize: 10, color: _grey)),
              pw.SizedBox(height: 5),
              pw.Text(DateFormat('EEE, d MMM yyyy').format(dep), style: pw.TextStyle(fontSize: 8, color: _grey)),
              pw.Text(DateFormat('HH:mm').format(dep), style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: _navy)),
            ]),
            pw.Column(children: [
              pw.Text('${h}h ${m}m', style: pw.TextStyle(fontSize: 9, color: _blue, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              pw.Container(width: 70, height: 1.5, color: _blue),
              pw.SizedBox(height: 4),
              pw.Text('Direct', style: pw.TextStyle(fontSize: 8, color: _grey)),
            ]),
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
              pw.Text(dCode, style: pw.TextStyle(fontSize: 34, fontWeight: pw.FontWeight.bold, color: _navy)),
              pw.Text(dCity, style: pw.TextStyle(fontSize: 10, color: _grey)),
              pw.SizedBox(height: 5),
              pw.Text(DateFormat('EEE, d MMM yyyy').format(arr), style: pw.TextStyle(fontSize: 8, color: _grey)),
              pw.Text(DateFormat('HH:mm').format(arr), style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: _navy)),
            ]),
          ]),
          pw.SizedBox(height: 12),
          pw.Divider(color: _border, height: 1),
          pw.SizedBox(height: 9),
          // Details row
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            _cell('CABIN',        cabin),
            _cell('BAGGAGE',      bag),
            _cell('SEAT',         'Check-in Req.'),
            _cell('GATE / TERM.', 'At Airport'),
          ]),
        ]),
      ),
    ]);
  }

  static pw.Widget _cell(String label, String val) => pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(label, style: pw.TextStyle(fontSize: 7, color: _grey, letterSpacing: 0.4)),
      pw.SizedBox(height: 3),
      pw.Text(val,   style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _navy)),
    ],
  );

  // ── Divider between segments ─────────────────────────────────────────────────
  static pw.Widget _divider() => pw.Row(
    children: List.generate(60, (i) => pw.Expanded(
      child: pw.Container(height: 1, color: i.isEven ? _steel : PdfColors.white),
    )),
  );

  // ── Passengers box ───────────────────────────────────────────────────────────
  static pw.Widget _paxBox(List<String> pax) => pw.Container(
    decoration: pw.BoxDecoration(color: _light, border: pw.Border.all(color: _border), borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5))),
    padding: const pw.EdgeInsets.all(13),
    child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Row(children: [
        pw.Text('PASSENGERS', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: _blue, letterSpacing: 1.2)),
        pw.SizedBox(width: 7),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: pw.BoxDecoration(color: _blue, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8))),
          child: pw.Text('${pax.length}', style: pw.TextStyle(fontSize: 8, color: PdfColors.white, fontWeight: pw.FontWeight.bold)),
        ),
      ]),
      pw.SizedBox(height: 8),
      ...pax.asMap().entries.map((e) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 3),
        child: pw.Text('${e.key + 1}.  ${e.value.toUpperCase()}', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: _navy)),
      )),
    ]),
  );

  // ── Booking summary box ──────────────────────────────────────────────────────
  static pw.Widget _sumBox({
    required bool isRT, required int count, required DateTime created,
    required double total, required ({PdfColor color, String label}) badge,
  }) => pw.Container(
    decoration: pw.BoxDecoration(color: _light, border: pw.Border.all(color: _border), borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5))),
    padding: const pw.EdgeInsets.all(13),
    child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Text('BOOKING SUMMARY', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: _blue, letterSpacing: 1.2)),
      pw.SizedBox(height: 8),
      pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
        _cell('TRIP TYPE',    isRT ? 'Round Trip' : 'One Way'),
        _cell('PASSENGERS',   '$count'),
        _cell('BOOKED ON',    DateFormat('d MMM yyyy').format(created)),
      ]),
      pw.SizedBox(height: 8),
      pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
        _cell('TOTAL PRICE', '${total.toStringAsFixed(2)} EGP'),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: pw.BoxDecoration(color: badge.color, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8))),
          child: pw.Text(badge.label, style: pw.TextStyle(fontSize: 9, color: PdfColors.white, fontWeight: pw.FontWeight.bold)),
        ),
      ]),
    ]),
  );

  // ── Status badge — driven by a single resolved status string ────────────────
  // Statuses: 'confirmed' | 'flown' | 'cancelled'
  static ({PdfColor color, String label}) _badge(String resolvedStatus) {
    switch (resolvedStatus) {
      case 'cancelled': return (color: _red,    label: 'CANCELLED');
      case 'flown':     return (color: _steel,  label: 'CONFIRMED & FLOWN');
      default:          return (color: _green,  label: 'CONFIRMED');
    }
  }

  static String _cabinLabel(String c) {
    switch (c.toLowerCase()) {
      case 'business': return 'Business';
      case 'first':    return 'First Class';
      default:         return 'Economy';
    }
  }
}
