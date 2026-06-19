import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image/image.dart' as img;
import 'package:printing/printing.dart';

class PDFService {

  static Future<File> generatePDFFromImage(
      Uint8List imageBytes,
      String filename,
      double pixelRatio,
      ) async {

    final pdf = pw.Document();


    final decodedImage = img.decodeImage(imageBytes);

    if (decodedImage == null) {
      throw Exception('Unable to decode image');
    }

    final imageWidth = decodedImage.width;
    final imageHeight = decodedImage.height;

    // const pageFormat = PdfPageFormat.a4;

    // final pdfPageWidth = pageFormat.availableWidth;
    // final pdfPageHeight = pageFormat.availableHeight;

    final pageWidth = PdfPageFormat.a4.width;
    final pageHeight = PdfPageFormat.a4.height;

    final sliceHeight =
    ((pageHeight * imageWidth) / pageWidth).toInt();


    for (int y = 4; y < imageHeight; y += sliceHeight) {

      final currentHeight =
      (y + sliceHeight > imageHeight)
          ? imageHeight - y
          : sliceHeight;

      final cropped = img.copyCrop(
        decodedImage,
        x: 0,
        y: y,
        width: imageWidth,
        height: currentHeight,
      );

      final bytes = Uint8List.fromList(
        img.encodePng(cropped),
      );

      final pageWidth = PdfPageFormat.a4.width;

      final pageHeight =
          pageWidth * currentHeight / imageWidth;

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat(
            pageWidth,
            pageHeight,
          ),

          margin: pw.EdgeInsets.zero,

          build: (context) {
            return pw.Image(
              pw.MemoryImage(bytes),

              width: pageWidth,

              height: pageHeight,

              fit: pw.BoxFit.fill,
            );
          },
        ),
      );
    }

    return await _savePDF(pdf, filename);
  }

  static Future<File> _savePDF(pw.Document pdf, String filename) async {
    final bytes = await pdf.save();
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes);
    return file;
  }

  static Future<void> sharePDF(File file) async {
    await Share.shareXFiles([XFile(file.path)], text: 'Here are your hotel booking details');
  }

  static Future<void> printPDF(File file) async {
    final bytes = await file.readAsBytes();
    await Printing.layoutPdf(onLayout: (_) => bytes);
  }
}