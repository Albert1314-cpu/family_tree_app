import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:io';
import '../models/family_tree.dart';
import '../models/member.dart';
import '../models/relationship.dart';

class PdfExportService {
  /// 导出家族谱为PDF
  static Future<void> exportFamilyTreeToPdf({
    required FamilyTree familyTree,
    required List<Member> members,
    required List<Relationship> relationships,
  }) async {
    final pdf = pw.Document();

    // 封面页
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(
                  familyTree.name,
                  style: pw.TextStyle(
                    fontSize: 32,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 20),
                if (familyTree.notes != null)
                  pw.Text(
                    familyTree.notes!,
                    style: pw.TextStyle(fontSize: 16),
                  ),
                pw.SizedBox(height: 40),
                pw.Text(
                  '家族谱',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  '生成时间: ${DateTime.now().toString().substring(0, 19)}',
                  style: pw.TextStyle(fontSize: 12),
                ),
              ],
            ),
          );
        },
      ),
    );

    // 成员列表页
    final membersPerPage = 15;
    for (int i = 0; i < members.length; i += membersPerPage) {
      final pageMembers = members.skip(i).take(membersPerPage).toList();
      
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return [
              pw.Header(
                level: 0,
                child: pw.Text(
                  '家族成员列表',
                  style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  // 表头
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('姓名', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('性别', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('出生日期', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('备注', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                    ],
                  ),
                  // 成员行
                  ...pageMembers.map((member) {
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(member.name),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(_getGenderText(member.gender)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            member.birthday != null
                                ? '${member.birthday!.year}-${member.birthday!.month.toString().padLeft(2, '0')}-${member.birthday!.day.toString().padLeft(2, '0')}'
                                : '-',
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(member.notes ?? '-'),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ];
          },
        ),
      );
    }

    // 打印和分享PDF
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  static String _getGenderText(Gender gender) {
    switch (gender) {
      case Gender.male:
        return '男';
      case Gender.female:
        return '女';
      case Gender.other:
        return '其他';
    }
  }
}

