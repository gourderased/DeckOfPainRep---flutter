import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(''),
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/settings'),
            icon: Image.asset(
              'assets/main_btn_settings.png',
              width: 42, height: 42,
            )
          )
        ]
      ),

      body: SafeArea(
        child: Column(
          children: [
            Spacer(flex: 1),

            Expanded(
              flex: 5,
              child: Center(
            child: Image.asset(
              'assets/main_logo.png',
              width: 300,
              height: 320,
              fit: BoxFit.contain,
            ),
              ),
            ),

            Expanded(
              flex: 3,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SizedBox(height: 10),

                    SizedBox(
                      width: 134,
                      height: 48,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)
                          )
                        ),


                        onPressed: () => Navigator.pushNamed(context, '/card'),
                        child: Text(
                          '운동 시작',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Pretendard',
                            color: Colors.black,
                          )
                        
                        ),
                      ),
                    ),

                    SizedBox(height: 16),

                    SizedBox(
                      width: 134,
                      height: 48,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)
                          )
                        ),
                        onPressed: () => Navigator.pushNamed(context, '/how'),
                        child: Text('운동 방법',
                            style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Pretendard',
                            color: Colors.black,
                          )
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Spacer(flex: 1),
          ],
        ),
        ),
    );
  }
}