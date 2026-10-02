import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoffman/core/widgets/index.dart';

void main() {
  testWidgets('FlowerBackground: the flower photo at 20% opacity, clipped '
      'to the box it fills', (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(width: 393, height: 500, child: FlowerBackground()),
        ),
      ),
    );

    final image = tester.widget<Image>(find.byType(Image));
    expect((image.image as AssetImage).assetName, FlowerBackground.asset);
    expect(
      tester
          .widget<Opacity>(
            find.descendant(
              of: find.byType(FlowerBackground),
              matching: find.byType(Opacity),
            ),
          )
          .opacity,
      FlowerBackground.opacity,
    );
    expect(FlowerBackground.opacity, 0.2);
    expect(tester.getSize(find.byType(FlowerBackground)), const Size(393, 500));
    expect(
      find.descendant(
        of: find.byType(FlowerBackground),
        matching: find.byType(ClipRect),
      ),
      findsOneWidget,
    );
  });
}
