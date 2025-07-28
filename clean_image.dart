import 'dart:io';
import 'package:image/image.dart';

void main() async {
  final filePath = 'C:\\Users\\mosta\\Desktop\\masar_jobs_application_Flutter\\assets\\image\\logo.png';
  final file = File(filePath);
  if (!await file.exists()) {

    print('Error: File not found at $filePath');
    return;
  }

  // Read the image file bytes
  final bytes = await file.readAsBytes();
  
  // Decode the image
  final image = decodeImage(bytes);

  if (image == null) {
    print('Error: Could not decode image. The file might be corrupt or in an unsupported format.');
    return;
  }

  // Re-encode the image as a PNG
  final pngBytes = encodePng(image);

  // Overwrite the original file with the cleaned version
  await file.writeAsBytes(pngBytes);

  print('Successfully cleaned and re-saved the image at $filePath');
}
