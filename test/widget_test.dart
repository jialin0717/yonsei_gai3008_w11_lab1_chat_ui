import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lab1_chat_ui/main.dart';

void main() {
  // 테스트 1: 앱 제목과 빈 상태 확인
  testWidgets('앱 제목과 빈 상태가 보인다', (tester) async {
    await tester.pumpWidget(const ChatLabApp());

    expect(find.text('AI Chat — 실습 1'), findsOneWidget);

    expect(find.byType(AnimatedList), findsOneWidget);

    expect(find.text('무엇이든 물어보세요'), findsOneWidget);
  });

  // 테스트 2: 입력창과 전송 버튼 확인
  testWidgets('메시지 입력창과 전송 버튼이 보인다', (tester) async {
    await tester.pumpWidget(const ChatLabApp());

    expect(find.byType(TextField), findsOneWidget);

    expect(find.byIcon(Icons.send), findsOneWidget);

    expect(find.text('메시지를 입력하세요'), findsOneWidget);
  });

  // 테스트 3: 사용자 메시지 전송 확인
  testWidgets('사용자 메시지를 전송할 수 있다', (tester) async {
    await tester.pumpWidget(const ChatLabApp());

    await tester.enterText(find.byType(TextField), '안녕하세요');

    await tester.tap(find.byIcon(Icons.send));

    // 상태 변경 및 메시지 삽입 애니메이션 처리
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('안녕하세요'), findsOneWidget);

    expect(find.text('무엇이든 물어보세요'), findsNothing);

    // 입력창이 비워졌는지 확인
    final textField = tester.widget<TextField>(find.byType(TextField));

    expect(textField.controller?.text, isEmpty);

    // MOCK 응답 완료까지 시간 진행
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 300));
  });

  // 테스트 4: 빈 메시지 전송 방지
  testWidgets('빈 메시지는 전송되지 않는다', (tester) async {
    await tester.pumpWidget(const ChatLabApp());

    await tester.tap(find.byIcon(Icons.send));
    await tester.pump();

    expect(find.text('무엇이든 물어보세요'), findsOneWidget);

    expect(find.byType(TextField), findsOneWidget);
  });

  // 테스트 5: 응답 대기 중 중복 전송 방지
  testWidgets('응답 대기 중 전송 버튼이 비활성화된다', (tester) async {
    await tester.pumpWidget(const ChatLabApp());

    await tester.enterText(find.byType(TextField), 'Flutter');

    await tester.tap(find.byIcon(Icons.send));
    await tester.pump();

    final sendButton = tester.widget<IconButton>(find.byType(IconButton));

    expect(sendButton.onPressed, isNull);

    // MOCK 응답 완료
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 300));
  });
}
