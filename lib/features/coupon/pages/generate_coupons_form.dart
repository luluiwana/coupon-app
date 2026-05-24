import 'package:flutter/material.dart';
import 'dart:math';
import 'package:coupons/core/database/database_helper.dart';
//widgets
import 'package:coupons/shared/widgets/title_bar.dart';
import 'package:coupons/shared/widgets/input_field.dart';
import 'package:coupons/shared/widgets/primary_button.dart';
import 'package:coupons/shared/widgets/error_alert.dart';

class GenerateCouponsForm extends StatefulWidget {
  const GenerateCouponsForm({super.key});

  @override
  State<GenerateCouponsForm> createState() => _GenerateCouponsFormState();
}

class _GenerateCouponsFormState extends State<GenerateCouponsForm> {
  final _operatorNameController = TextEditingController();
  final _locationController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: TitleBar('Generate Coupons'),
      ),
      body: Container(
        color: const Color.fromARGB(255, 231, 230, 230),
        child: SafeArea(
          child: Container(
            margin: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Fill in the details to generate coupons',
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Inter',
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 20),
                //nama operator
                InputField(
                  controller: _operatorNameController,
                  label: 'Operator Name',
                  icon: Icons.person,
                ),

                InputField(
                  controller: _locationController,
                  label: 'Location',
                  icon: Icons.location_on,
                ),
                const SizedBox(height: 20),
                PrimaryButton(
                  label: 'Submit',
                  onPressed: startBatchProcessing,
                  icon: Icons.start,
                ),
                SizedBox(height: 20),
                // PrimaryButton(
                //   label: 'HAPUS DATA',
                //   onPressed: () async {
                //     await deleteAllData();
                //   },
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void startBatchProcessing() async {
    final operatorName = _operatorNameController.text;
    final location = _locationController.text;
    final db = DatabaseHelper.instance;

    //----------------------------------------------------------------
    //! GENERATE COUPONS LOGIC
    //----------------------------------------------------------------

    // A. GENERATE BATCH

    //1. Cek data batch terakhir untuk menentukan batch number berikutnya,jika batch number sudah mencapai batas maksimal (2 batch), maka menampilkan dialog error
    final nextBatchId = await validateBatchId();
    if (nextBatchId == null) {
      return; // Hentikan proses jika batch number melebihi batas
    }
    // 2. Validasi input

    if (operatorName.isEmpty || location.isEmpty) {
      ErrorAlert.show(context, 'Please fill in all fields');
      return; // Hentikan proses jika validasi gagal
    }
    // 3. Masukkan data batch ke table batches
    final int batchId = await db.insertBatchData({
      'operator_name': operatorName,
      'location': location,
      'id': nextBatchId,
    });

    //B. GENERATE BOXES
    // Generate 5 box per batch
    for (int box = 0; box < 5; box++) {
      var lastBoxId = await db.insertBoxData(batchId);

      //define min and max serial number for coupons
      var lastSerialNumber = await db.getLastCouponSerialNumber();
      int minSerialNumber = lastSerialNumber + 1;
      int maxSerialNumber =
          lastSerialNumber + 1000; // Setiap box berisi 1000 kupon

      // Generate Pemenang dan jumlah hadiah untuk box ini
      Map<int, int> winningSerialNumbers = await getWinningSerialNumbers(
        minSerialNumber,
        maxSerialNumber,
      );

      // C. GENERATE COUPONS
      List<Map<String, dynamic>> couponData = [];

      for (int i = 0; i < 1000; i++) {
        int serialNumber = minSerialNumber + i;
        // format serial number dengan leading zeros menjadi 5 digit
        var formattedSerialNumber = serialNumber.toString().padLeft(5, '0');
        // Cek apakah serial number ini adalah pemenang dan dapatkan jumlah hadiahnya, jika tidak menang maka hadiahnya 0
        int prizeAmount = winningSerialNumbers[serialNumber] ?? 0;

        // append coupon data to couponData list
        couponData.add({
          'serialnumber': formattedSerialNumber,
          'box_id': lastBoxId,
          'amount': prizeAmount,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      //Insert data
      await db.insertCoupons(couponData);
      if (box == 4) {
        //navigate to production log report page
        if (context.mounted) {
          Navigator.pushNamed(context, '/production-log-report');
        }
      }
    }
  }

  Future<Map<int, int>> getWinningSerialNumbers(int min, int max) async {
    const int requestedCount = 190; // Jumlah serial number yang menang per box
    // membuat unique random numbers dalam rentang min dan max
    final winningSerialNumbers = <int>{};
    final winningSerialNumbersWithPrizes =
        <
          int,
          int
        >{}; // Map untuk menyimpan nomor seri yang menang beserta jumlah hadiahnya

    for (int i = 0; i < requestedCount; i++) {
      final randomNumber = await getUniqueRandomNumber(
        min,
        max,
        winningSerialNumbers,
      );
      winningSerialNumbers.add(randomNumber);
      // 5 orang mendapatkan 100ribu
      if (winningSerialNumbersWithPrizes.length < 5) {
        winningSerialNumbersWithPrizes[randomNumber] = 100000;
      } //10 orang mendapatkan 50ribu
      else if (winningSerialNumbersWithPrizes.length < 15) {
        winningSerialNumbersWithPrizes[randomNumber] = 50000;
      } // 25 orang mendapatkan 20ribu
      else if (winningSerialNumbersWithPrizes.length < 40) {
        winningSerialNumbersWithPrizes[randomNumber] = 20000;
      } // 50 orang mendapatkan 10ribu
      else if (winningSerialNumbersWithPrizes.length < 90) {
        winningSerialNumbersWithPrizes[randomNumber] = 10000;
      } // sisanya mendapatkan 5ribu
      else {
        winningSerialNumbersWithPrizes[randomNumber] = 5000;
      }
    }
    // return serial number yang menang beserta jumlah hadiahnya
    return winningSerialNumbersWithPrizes;
  }

  Future<int> getUniqueRandomNumber(
    int min,
    int max,
    Set<int> existingNumbers,
  ) async {
    final random = Random();
    int randomNumber;

    //1. Generate unique random number dalam rentang min dan max
    //2. Cek apakah random number yang dihasilkan berada dalam existingNumbers atau berdekatan dengan nomor yang sudah ada
    do {
      randomNumber = min + random.nextInt(max - min + 1);
    } while (existingNumbers.contains(randomNumber) ||
        existingNumbers.contains(randomNumber - 1) ||
        existingNumbers.contains(randomNumber + 1));

    return randomNumber;
  }

  Future<int?> validateBatchId() async {
    final db = DatabaseHelper.instance;
    final lastBatch = await db.getLatestBatch();
    var nextBatchId = lastBatch != null ? lastBatch + 1 : 1;
    if (nextBatchId > 2) {
      // Tampilkan dialog error jika batch number melebihi batas
      ErrorAlert.show(context, 'Maksimum batch number terlampaui.');
      return null; // Kembalikan null untuk menandakan batch number melebihi batas
    }
    return nextBatchId;
  }

  Future<void> deleteAllData() async {
    final db = DatabaseHelper.instance;
    await db.deleteAllData();
  }
}
