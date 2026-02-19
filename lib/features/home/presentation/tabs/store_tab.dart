import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StoreTab extends StatelessWidget {
  const StoreTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             Icon(Icons.storefront_rounded, size: 80, color: Colors.grey.shade400),
             const SizedBox(height: 16),
             Text(
               'Tienda',
               style: GoogleFonts.nunito(
                 fontSize: 24,
                 fontWeight: FontWeight.bold,
                 color: Colors.grey.shade600,
               ),
             ),
             const SizedBox(height: 8),
             Text(
               'Próximamente',
               style: GoogleFonts.nunito(
                 fontSize: 16,
                 color: Colors.grey.shade500,
               ),
             ),
          ],
        ),
      ),
    );
  }
}
