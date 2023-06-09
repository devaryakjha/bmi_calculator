import 'package:bmi_calculator/common/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmi_calculator/bloc/bmi_bloc.dart';
import 'package:bmi_calculator/common/utils.dart';
import 'package:bmi_calculator/common/widgets/gender_selector.dart';
import 'package:bmi_calculator/common/widgets/height_selector.dart';
import 'package:bmi_calculator/common/widgets/weight_and_age.dart';
import 'package:go_router/go_router.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = textThemeOf(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'BMI Calculator',
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      body: BlocBuilder<BmiBloc, BmiState>(
        builder: (context, state) {
          return Scrollbar(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    GenderSelector(state: state),
                    const SizedBox(height: 16),
                    HeightSelector(state: state),
                    const SizedBox(height: 16),
                    WeightAndAge(state: state),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => context.push(Routes.results),
                        child: const Text('Calculate BMI'),
                      ),
                    )
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
