import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:coupons/core/database/database_helper.dart';
//widgets
import 'package:coupons/shared/widgets/title_bar.dart';

class ProductionLogReport extends StatelessWidget {
  const ProductionLogReport({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: TitleBar('Production Log Report'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(5),
        children: [_buildBatchSection()],
      ),
    );
  }
}

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: TitleBar('Production Log Report'),
    ),
    body: ListView(
      padding: const EdgeInsets.all(5),
      children: [_buildBatchSection()],
    ),
  );
}

Widget _buildBatchSection() {
  final db = DatabaseHelper.instance;
  return FutureBuilder<List<Map<String, dynamic>>>(
    future: db.getBatches(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text('Error: ${snapshot.error}'),
        );
      }
      final data = snapshot.data ?? <Map<String, dynamic>>[];
      if (data.isEmpty) {
        return const Center(child: Text('No batch data available'));
      }
      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: data.length,
        itemBuilder: (context, index) {
          final batch = data[index];
          final created =
              DateTime.tryParse(batch['created_at'] as String? ?? '') ??
              DateTime.now();
          return BatchSection(
            batchNumber: batch['id'] as int,
            operatorName: batch['operator_name'] as String? ?? '',
            location: batch['location'] as String? ?? '',
            date: DateFormat('dd-MMM-yyyy').format(created),
            time: DateFormat('HH:mm').format(created),
          );
        },
      );
    },
  );
}

class BatchSection extends StatefulWidget {
  final int batchNumber;
  final String operatorName;
  final String location;
  final String date;
  final String time;

  const BatchSection({
    super.key,
    required this.batchNumber,
    required this.operatorName,
    required this.location,
    required this.date,
    required this.time,
  });

  @override
  State<BatchSection> createState() => _BatchSectionState();
}

class _BatchSectionState extends State<BatchSection> {
  late Future<List<Map<String, dynamic>>> _couponsFuture;
  int? _selectedNominal;

  @override
  void initState() {
    super.initState();
    _couponsFuture = DatabaseHelper.instance.getProductionReport(
      widget.batchNumber,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoTable(),
            const SizedBox(height: 16),
            const Divider(thickness: 1),
            const SizedBox(height: 8),
            _buildCouponDataTable(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTable() {
    final infoData = {
      'No Batch:': widget.batchNumber.toString(),
      'Nama Operator:': widget.operatorName,
      'Lokasi:': widget.location,
      'Tanggal / Jam:': '${widget.date} / ${widget.time}',
    };

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Table(
        columnWidths: const {0: FixedColumnWidth(120), 1: FlexColumnWidth()},
        children: infoData.entries.map((entry) {
          return TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  entry.key,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(entry.value),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCouponDataTable() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _couponsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 120,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final allCoupons = snapshot.data ?? <Map<String, dynamic>>[];
        if (allCoupons.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text('No coupons for this batch'),
          );
        }

        final nominals = allCoupons
            .map((c) => c['amount'] is int ? c['amount'] as int : 0)
            .toSet()
            .toList()
          ..sort();

        final coupons = _selectedNominal == null
            ? allCoupons
            : allCoupons
                .where(
                  (c) =>
                      (c['amount'] is int ? c['amount'] as int : 0) ==
                      _selectedNominal,
                )
                .toList();

        final _nomFmt = NumberFormat.currency(
          locale: 'id_ID',
          symbol: 'Rp ',
          decimalDigits: 0,
        );

        final int perPage = 10;
        final int effectiveRowsPerPage =
            coupons.isEmpty ? 1 : (coupons.length < perPage ? coupons.length : perPage);

        final source = CouponDataSource(coupons);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                children: [
                  const Text(
                    'Filter Nominal:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<int?>(
                    value: _selectedNominal,
                    hint: const Text('Semua'),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Semua'),
                      ),
                      ...nominals.map(
                        (n) => DropdownMenuItem<int?>(
                          value: n,
                          child: Text(_nomFmt.format(n)),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedNominal = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            if (coupons.isEmpty)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('Tidak ada data untuk nominal ini'),
              )
            else
              PaginatedDataTable(
                columns: const [
                  DataColumn(label: Text('No Box')),
                  DataColumn(label: Text('No Kupon')),
                  DataColumn(
                    label: Text(
                      'Nominal',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(label: Text('Keterangan')),
                ],
                source: source,
                rowsPerPage: effectiveRowsPerPage,
                availableRowsPerPage: const [10],
                showCheckboxColumn: false,
                columnSpacing: 12,
              ),
          ],
        );
      },
    );
  }
}

class CouponDataSource extends DataTableSource {
  final List<Map<String, dynamic>> coupons;
  final NumberFormat _fmt = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  CouponDataSource(this.coupons);

  @override
  DataRow? getRow(int index) {
    if (index >= coupons.length) return null;
    final coupon = coupons[index];
    final nominal = coupon['amount'] is int ? coupon['amount'] as int : 0;
    final keterangan = coupon['keterangan'] ?? '';
    return DataRow.byIndex(
      index: index,
      cells: [
        DataCell(Text('${coupon['box_id'] ?? ''}')),
        DataCell(Text('${coupon['serialnumber'] ?? ''}')),
        DataCell(Text(_fmt.format(nominal))),
        DataCell(Text(keterangan)),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => coupons.length;

  @override
  int get selectedRowCount => 0;
}
