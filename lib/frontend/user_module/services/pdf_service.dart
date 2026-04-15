import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'dart:convert';
import 'package:http_parser/http_parser.dart';

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PdfService {
   final String? baseUrl = dotenv.env['BASE_URL'];
  // Generate and save a PDF report
  static Future<File> generateFinancialReport({
    required double totalIncome,
    required double totalExpenses,
    required double netAmount,
    required Map<String, double> expenseData,
    required Map<String, double> incomeData,
    required String userName,
    Uint8List? expenseChartImage,
    Uint8List? incomeChartImage,
    Uint8List? monthlyTrendsChartImage,
  }) async {
    final pdf = pw.Document();
    
    // Try to load fonts
    final fontData = await rootBundle.load("assets/fonts/OpenSans-Regular.ttf");
    final ttf = pw.Font.ttf(fontData);
    
    // Fallback to default font if custom font fails
    final font = ttf ?? pw.Font.helvetica();
    
    // Add pages to the PDF
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        footer: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Xpense App',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'Page ${context.pageNumber} of ${context.pagesCount}',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontStyle: pw.FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
        build: (pw.Context context) => [
          _buildHeader(userName),
          _buildSummary(totalIncome, totalExpenses, netAmount),
          pw.SizedBox(height: 20),
          _buildExpensesSection(expenseData, expenseChartImage),
          pw.SizedBox(height: 20),
          _buildIncomeSection(incomeData, incomeChartImage),
          pw.SizedBox(height: 20),
          // Add monthly trends section
          if (monthlyTrendsChartImage != null)
            _buildMonthlyTrendsSection(monthlyTrendsChartImage),
        ],
      ),
    );
    
    // Save the PDF
    return saveDocument(
      name: 'financial_report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf', 
      pdf: pdf
    );
  }


  static Future<Map<String, dynamic>> sendPdfToServer(
    File pdfFile, {
    String? userId,
    double? totalIncome,
    double? totalExpenses,
    double? netAmount,
  }) async {
    try {
      // Get base URL from environment variable
      final baseUrl = dotenv.env['BASE_URL'] ?? 'https://ml-based-personal-finance-optimizer.onrender.com';
      final uri = Uri.parse('$baseUrl/api/pdf/upload');
      
      // Create multipart request
      final request = http.MultipartRequest('POST', uri);
      
      // Add the PDF file to the request
      request.files.add(await http.MultipartFile.fromPath(
        'file', 
        pdfFile.path,
        filename: pdfFile.path.split('/').last,
        contentType: MediaType('application', 'pdf'),
      ));
      
      // Add additional form data if provided
      if (userId != null) {
        request.fields['userId'] = userId;
        print("Adding userId: $userId");
      }
      if (totalIncome != null) {
        request.fields['totalIncome'] = totalIncome.toString();
        print("Adding totalIncome: $totalIncome");
      }
      if (totalExpenses != null) {
        request.fields['totalExpenses'] = totalExpenses.toString();
        print("Adding totalExpenses: $totalExpenses");
      }
      if (netAmount != null) {
        request.fields['netAmount'] = netAmount.toString();
        print("Adding netAmount: $netAmount");
      }
      
      // Add dummy field to ensure form data is recognized
      request.fields['_appData'] = 'true';
      
      // Don't set Content-Type header - let the browser set it automatically with boundary
      
      // Debug: Print request details
      print("Sending PDF to server:");
      print("URL: $uri");
      print("File path: ${pdfFile.path}");
      print("File size: ${await pdfFile.length()} bytes");
      print("Request fields: ${request.fields}");
      print("Request files: ${request.files.map((f) => '${f.field}: ${f.filename}').toList()}");
      
      // Send the request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        print("PDF sent to server successfully");
        print("Response: ${response.body}");
        
        // Parse response to get email and file info
        final responseData = json.decode(response.body);
        final userEmail = responseData['user']['email'];
        final filePath = responseData['file']['filePath'];
        final downloadUrl = responseData['file']['downloadUrl'];
        
        print("User email from response: $userEmail");
        print("File path from response: $filePath");
        print("Download URL: $downloadUrl");
        
        return {
          'success': true,
          'email': userEmail,
          'filePath': filePath,
          'downloadUrl': downloadUrl,
          'response': responseData
        };
      } else {
        print("Failed to send PDF: ${response.statusCode}");
        print("Response: ${response.body}");
        throw Exception('Server returned status code: ${response.statusCode}');
      }
    } catch (e) {
      print("Error sending PDF to server: $e");
      throw Exception('Failed to send PDF to server: $e');
    }
  }

  
  // Build header section of the PDF
  static pw.Widget _buildHeader(String userName) {
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
                  'Financial Analysis Report',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Generated on ${DateFormat('MMMM d, yyyy').format(DateTime.now())}',
                  style: pw.TextStyle(
                    fontSize: 14,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ),
            pw.Container(
              padding: pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue50,
                borderRadius: pw.BorderRadius.circular(10),
                border: pw.Border.all(color: PdfColors.blue200),
              ),
              child: pw.Text(
                userName,
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue700,
                ),
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Divider(thickness: 1),
      ],
    );
  }
  
  // Build financial summary section
  static pw.Widget _buildSummary(double totalIncome, double totalExpenses, double netAmount) {
    return pw.Padding(
      padding: pw.EdgeInsets.symmetric(vertical: 15),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Financial Summary',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 15),
          pw.Row(
            children: [
              _buildSummaryCard('Total Income', totalIncome, PdfColors.green700),
              pw.SizedBox(width: 15),
              _buildSummaryCard('Total Expenses', totalExpenses, PdfColors.red700),
              pw.SizedBox(width: 15),
              _buildSummaryCard('Net Amount', netAmount, netAmount >= 0 ? PdfColors.blue700 : PdfColors.orange700),
            ],
          ),
        ],
      ),
    );
  }

  // Build a summary card for financial data
  static pw.Expanded _buildSummaryCard(String title, double amount, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: PdfColors.white,
          border: pw.Border.all(color: color.shade(50)),
          borderRadius: pw.BorderRadius.circular(8),
          boxShadow: [
            pw.BoxShadow(
              color: PdfColors.grey300,
              offset: const PdfPoint(0, 2),
              blurRadius: 2,
            ),
          ],
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 12,
                color: PdfColors.grey800,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              '₹${amount.toStringAsFixed(2)}',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Build expenses section with pie chart (if available)
  static pw.Widget _buildExpensesSection(Map<String, double> expenseData, Uint8List? chartImage) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Expense Breakdown',
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 15),
        
        // Show chart image if available
        if (chartImage != null) ...[
          pw.Center(
            child: pw.Image(
              pw.MemoryImage(chartImage),
              height: 200,
              fit: pw.BoxFit.contain,
            ),
          ),
          pw.SizedBox(height: 15),
        ],
        
        // Show expense table
        pw.Table.fromTextArray(
          headerStyle: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.white,
          ),
          headerDecoration: pw.BoxDecoration(
            color: PdfColors.red700,
          ),
          cellAlignment: pw.Alignment.centerLeft,
          cellStyle: pw.TextStyle(
            fontSize: 12,
          ),
          headerAlignment: pw.Alignment.centerLeft,
          data: <List<String>>[
            ['Category', 'Amount (₹)', 'Percentage'],
            ...expenseData.entries.map((entry) {
              final total = expenseData.values.reduce((sum, value) => sum + value);
              final percentage = total > 0 ? (entry.value / total * 100) : 0;
              return [
                entry.key,
                entry.value.toStringAsFixed(2),
                '${percentage.toStringAsFixed(1)}%',
              ];
            }).toList(),
          ],
        ),
      ],
    );
  }
  
  // Build income section with pie chart (if available)
  static pw.Widget _buildIncomeSection(Map<String, double> incomeData, Uint8List? chartImage) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Income Breakdown',
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 15),
        
        // Show chart image if available
        if (chartImage != null) ...[
          pw.Center(
            child: pw.Image(
              pw.MemoryImage(chartImage),
              height: 200,
              fit: pw.BoxFit.contain,
            ),
          ),
          pw.SizedBox(height: 15),
        ],
        
        // Show income table
        pw.Table.fromTextArray(
          headerStyle: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.white,
          ),
          headerDecoration: pw.BoxDecoration(
            color: PdfColors.green700,
          ),
          cellAlignment: pw.Alignment.centerLeft,
          cellStyle: pw.TextStyle(
            fontSize: 12,
          ),
          headerAlignment: pw.Alignment.centerLeft,
          data: <List<String>>[
            ['Category', 'Amount (₹)', 'Percentage'],
            ...incomeData.entries.map((entry) {
              final total = incomeData.values.reduce((sum, value) => sum + value);
              final percentage = total > 0 ? (entry.value / total * 100) : 0;
              return [
                entry.key,
                entry.value.toStringAsFixed(2),
                '${percentage.toStringAsFixed(1)}%',
              ];
            }).toList(),
          ],
        ),
      ],
    );
  }
  
  // Build monthly trends section with chart
  static pw.Widget _buildMonthlyTrendsSection(Uint8List chartImage) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Monthly Trends',
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 15),
        
        pw.Center(
          child: pw.Image(
            pw.MemoryImage(chartImage),
            height: 250,
            fit: pw.BoxFit.contain,
          ),
        ),
        
        pw.SizedBox(height: 10),
        
        pw.Container(
          padding: pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: PdfColors.blue50,
            borderRadius: pw.BorderRadius.circular(8),
            border: pw.Border.all(color: PdfColors.blue200),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              _buildLegendItem(PdfColors.green700, 'Income'),
              pw.SizedBox(width: 20),
              _buildLegendItem(PdfColors.red700, 'Expenses'),
              pw.SizedBox(width: 20),
              _buildLegendItem(PdfColors.blue700, 'Net'),
            ],
          ),
        ),
      ],
    );
  }
  
  // Helper to build legend items for the monthly trends chart
  static pw.Widget _buildLegendItem(PdfColor color, String label) {
    return pw.Row(
      children: [
        pw.Container(
          width: 12,
          height: 12,
          decoration: pw.BoxDecoration(
            color: color,
            shape: pw.BoxShape.circle,
          ),
        ),
        pw.SizedBox(width: 5),
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 10,
            color: PdfColors.grey800,
          ),
        ),
      ],
    );
  }

  // Save PDF to file and return the file
  static Future<File> saveDocument({
    required String name,
    required pw.Document pdf,
  }) async {
    final bytes = await pdf.save();

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$name');

    await file.writeAsBytes(bytes);
    return file;
  }
  
  // Open the generated PDF
  static Future<void> openPDF(File file) async {
    final url = file.path;
    await OpenFile.open(url);
  }
  
  // Preview and print a PDF
  static Future<void> printPDF(pw.Document pdf) async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }
} 