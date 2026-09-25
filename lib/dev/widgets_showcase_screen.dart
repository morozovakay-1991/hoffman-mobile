import 'package:flutter/material.dart';
import 'package:hoffman/core/theme/index.dart';
import 'package:hoffman/core/widgets/index.dart';

/// Dev-only screen listing every `core/widgets` component. Launched from
/// `lib/main_showcase.dart`.
class WidgetsShowcaseScreen extends StatelessWidget {
  const WidgetsShowcaseScreen({super.key});

  static const _description =
      'Lorem Ipsum is simply dummy text of the printing and typesetting '
      'industry. Lorem Ipsum has been the industry standard dummy text.';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Widgets showcase')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          const _Section('AppButton'),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              AppButton(
                label: 'Продолжить',
                variant: AppButtonVariant.secondary,
                trailingIcon: Icons.arrow_forward_rounded,
                onPressed: () {},
              ),
              AppButton(
                label: 'Читать',
                trailingIcon: Icons.arrow_forward_rounded,
                onPressed: () {},
              ),
              AppButton(label: 'Сохранить', onPressed: () {}),
              AppButton(
                label: 'Начать',
                variant: AppButtonVariant.text,
                trailingIcon: Icons.arrow_forward_rounded,
                onPressed: () {},
              ),
              const AppButton(
                label: 'Войти',
                trailingIcon: Icons.arrow_forward_rounded,
                onPressed: null,
              ),
              const AppButton(
                label: 'Войти',
                variant: AppButtonVariant.secondary,
                onPressed: null,
              ),
            ],
          ),
          const _Section('AppCard'),
          const AppCard(child: Text('Обводка grey 0.5px')),
          const SizedBox(height: AppSpacing.sm),
          AppCard(onTap: () {}, child: const Text('С onTap (ripple)')),
          const SizedBox(height: AppSpacing.sm),
          const AppCard(borderColor: null, child: Text('Без обводки')),
          const _Section('AppTextField'),
          const AppTextField(
            label: 'Пароль',
            isRequired: true,
            obscureText: true,
          ),
          const SizedBox(height: AppSpacing.md),
          const AppTextField(
            label: 'Номер телефона',
            isRequired: true,
            keyboardType: TextInputType.phone,
            helperText:
                'Введите номер телефона, который указывали при прохождении '
                'Процесса Хоффмана',
          ),
          const SizedBox(height: AppSpacing.md),
          const AppTextField(
            label: 'Email',
            isRequired: true,
            errorText: 'Неверный формат email',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: AppSpacing.md),
          const AppTextField(label: 'Пароль', isRequired: true, enabled: false),
          const SizedBox(height: AppSpacing.md),
          const AppTextField(
            label: 'Email',
            isRequired: true,
            hintText: 'example@gmail.com',
            fillColor: AppColors.lightBlueTint,
          ),
          const SizedBox(height: AppSpacing.md),
          const AppTextField(hintText: '___   ___   ___   ___   ___   ___'),
          const _Section('AppBadge'),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              AppBadge(label: 'темы', onTap: () {}),
              AppBadge(label: 'все', onTap: () {}),
              AppBadge(label: 'инструменты', onTap: () {}),
              const AppBadge(
                label: 'выражение',
                variant: AppBadgeVariant.tinted,
              ),
            ],
          ),
          const _Section('MeditationCard'),
          MeditationCard(
            title: 'Visioning – образ будущего',
            cover: const ColoredBox(color: AppColors.blueTint),
            duration: '25 минут',
            description: _description,
            actionLabel: 'Начать',
            onTap: () {},
          ),
          const _Section('ArticleListCard'),
          ArticleListCard(
            title: 'Стресс, неудовлетворенность, одиночество',
            cover: const ColoredBox(color: AppColors.blueTint),
            date: 'Март, 2025',
            description: 'Откуда они берутся и как с ними обходиться',
            actionLabel: 'Читать',
            onTap: () {},
          ),
          const _Section('ToolListCard'),
          ToolListCard(
            title: 'Выражение гнева',
            description: _description,
            tag: 'выражение',
            actionLabel: 'Читать',
            onTap: () {},
          ),
          const _Section('ThemeListCard — tap to toggle'),
          const _ThemeListCardDemo(),
          const _Section('LoadingIndicator'),
          const SizedBox(height: 80, child: LoadingIndicator()),
          const _Section('ErrorStateWidget'),
          SizedBox(
            height: 160,
            child: ErrorStateWidget(
              message: 'Не удалось загрузить данные',
              onRetry: () {},
            ),
          ),
          const _Section('EmptyStateWidget'),
          const SizedBox(
            height: 160,
            child: EmptyStateWidget(message: 'Здесь пока пусто'),
          ),
          const _Section('EmptyStateWidget — locked (Diary)'),
          const SizedBox(
            height: 160,
            child: EmptyStateWidget(
              message: 'Этот день заблокирован.\nПопробуйте завтра',
              icon: Icons.lock,
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeListCardDemo extends StatefulWidget {
  const _ThemeListCardDemo();

  @override
  State<_ThemeListCardDemo> createState() => _ThemeListCardDemoState();
}

class _ThemeListCardDemoState extends State<_ThemeListCardDemo> {
  var _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return ThemeListCard(
      title: 'Границы',
      subtitle: 'сложности в отношениях / конфликтные ситуации / границы',
      cover: const ColoredBox(color: AppColors.blueTint),
      body:
          'Накалился конфликт. Недопонимание. Упреки, молчание, страхи.\n'
          'Первый важный шаг: разобрать для себя перенос. Что именно '
          'происходит?\n'
          'И все это не приводит к решению конфликта. Это все старая история.',
      actionLabel: 'Читать',
      isExpanded: _isExpanded,
      onTap: () => setState(() => _isExpanded = !_isExpanded),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.sm),
      child: Text(title, style: Theme.of(context).textTheme.labelMedium),
    );
  }
}
