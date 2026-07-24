import 'package:flutter/material.dart';

class AppBannerAdReserve extends StatelessWidget {
  const AppBannerAdReserve({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 75,
      width: double.infinity,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF222A2E), Color(0xFF151B1E)],
        ),
        border: Border(
          top: BorderSide(color: Color(0xFF4E5A60)),
          bottom: BorderSide(color: Color(0xFF050607)),
        ),
      ),
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.3,
        child: Container(
          width: 320,
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFAAB4B9),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: const Color(0xFF9AA6AA)),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF34A9E8),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: const Text(
                  'Ad',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 9),
              const Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mock banner placement',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Color(0xFF101416),
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'Google AdMob style preview',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Color(0xFF546166),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.info_outline_rounded, color: Color(0xFF546166)),
            ],
          ),
        ),
      ),
    );
  }
}
