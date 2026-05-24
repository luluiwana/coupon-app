import 'package:flutter/material.dart';
import 'package:coupons/core/database/database_helper.dart';
//widgets
import 'package:coupons/shared/widgets/title_bar.dart';
import 'package:coupons/shared/widgets/primary_button.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});
  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _totalCoupons = 0;
  int _totalBatches = 0;
  int _totalBoxes = 0;

  @override
  void initState() {
    super.initState();
    refreshData();
  }

  Future<void> _fetchTotalCoupons() async {
    final db = DatabaseHelper.instance;
    final total = await db.getTotalCoupons();

    setState(() {
      _totalCoupons = total;
    });
  }

  Future<void> _fetchTotalBatches() async {
    final db = DatabaseHelper.instance;
    final total = await db.getTotalBatches();

    setState(() {
      _totalBatches = total;
    });
  }

  Future<void> _fetchTotalBoxes() async {
    final db = DatabaseHelper.instance;
    final total = await db.getTotalBoxes();

    setState(() {
      _totalBoxes = total;
    });
  }


  Future<void> refreshData() async {
    await _fetchTotalCoupons();
    await _fetchTotalBatches();
    await _fetchTotalBoxes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: TitleBar('Coupon Pro'),
      ),
      body: Container(
        color: const Color.fromARGB(255, 231, 230, 230),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    await refreshData();
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            onPressed: refreshData,
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            icon: const Icon(Icons.refresh),
                          ),
                        ),
                        SizedBox(height: 10),
                        SizedBox(
                          child: Stack(
                            // fit: StackFit.expand,
                            children: [
                              Image.asset(
                                'assets/images/couponbg.png',
                                fit: BoxFit.cover,
                              ),
                              Positioned(
                                top: 25,
                                left: 40,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    RichText(
                                          text: TextSpan(
                                            children: [
                                              TextSpan(
                                                text: _totalCoupons.toString(),
                                                style: TextStyle(
                                                  fontSize: 40,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              TextSpan(
                                                text: '\nCoupons Generated',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    SizedBox(height: 15),
                                    TextButton.icon(
                                      onPressed: () {
                                        Navigator.pushNamed(context, '/production-log-report');
                                      },
                                      style: TextButton.styleFrom(
                                        backgroundColor: const Color.fromARGB(
                                          102,
                                          255,
                                          255,
                                          255,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 0,
                                        ),
                                      ),
                                      icon: Icon(
                                        Icons.chevron_right,
                                        color: Colors.white,
                                      ),
                                      label: Text(
                                        'View Production Log',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 20),
                        // 2 cards side by side
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.9,
                          child: Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 100,
                                  padding: const EdgeInsets.all(16),
                                  alignment: Alignment.topLeft,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: SizedBox(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Text(
                                          _totalBatches.toString(),
                                          style: TextStyle(
                                            fontSize: 40,
                                            fontFamily: 'Inter',
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                  
                                        Text(
                                          'Executed Batches',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontFamily: 'Inter',
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 20),
                              Expanded(
                                child: Container(
                                  height: 100,
                                  padding: const EdgeInsets.all(16),
                                  alignment: Alignment.topLeft,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: SizedBox(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Text(
                                          _totalBoxes.toString(),
                                          style: TextStyle(
                                            fontSize: 40,
                                            fontFamily: 'Inter',
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                  
                                        Text(
                                          'Coupon Boxes',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontFamily: 'Inter',
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 30.0),
                child: PrimaryButton(
                  label: 'Generate Coupons',
                  icon: Icons.add,
                  onPressed: () {
                    Navigator.pushNamed(context, '/generate-coupons-form');
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

 
}
