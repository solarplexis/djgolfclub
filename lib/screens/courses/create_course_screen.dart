import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/course.dart';
import '../../providers/course_provider.dart';
import '../../services/openai_course_service.dart';
import '../../theme/app_theme.dart';

class CreateCourseScreen extends StatefulWidget {
  final Course? course;
  const CreateCourseScreen({super.key, this.course});

  @override
  State<CreateCourseScreen> createState() => _CreateCourseScreenState();
}

class _CreateCourseScreenState extends State<CreateCourseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _aiQueryCtrl = TextEditingController();
  late final _holeCountCtrl =
      TextEditingController(text: (widget.course?.holeCount ?? 18).toString());
  late int _holeCount = widget.course?.holeCount ?? 18;
  late List<int> _pars;
  bool _saving = false;
  bool _aiLoading = false;

  bool get _isEditing => widget.course != null;

  @override
  void initState() {
    super.initState();
    if (widget.course != null) {
      _nameCtrl.text = widget.course!.name;
      _pars = widget.course!.holes.map((h) => h.par).toList();
    } else {
      _pars = List.filled(_holeCount, 4);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _aiQueryCtrl.dispose();
    _holeCountCtrl.dispose();
    super.dispose();
  }

  Future<void> _lookupWithAi() async {
    final query = _aiQueryCtrl.text.trim();
    if (query.isEmpty) return;
    setState(() => _aiLoading = true);
    try {
      final course = await OpenAiCourseService.fetchCourse(query);
      setState(() {
        _nameCtrl.text = course.name;
        _holeCount = course.holeCount;
        _holeCountCtrl.text = course.holeCount.toString();
        _pars = course.holes.map((h) => h.par).toList();
      });
      _aiQueryCtrl.clear();
    } on CourseAiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _aiLoading = false);
    }
  }

  void _setHoleCount(int count) {
    setState(() {
      _holeCount = count;
      if (count > _pars.length) {
        _pars = [..._pars, ...List.filled(count - _pars.length, 4)];
      } else {
        _pars = _pars.sublist(0, count);
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final holes = List.generate(
      _holeCount,
      (i) => Hole(number: i + 1, par: _pars[i]),
    );
    if (_isEditing) {
      final updated = Course(
          id: widget.course!.id, name: _nameCtrl.text.trim(), holes: holes);
      await context.read<CourseProvider>().updateCourse(updated);
    } else {
      final course = Course(name: _nameCtrl.text.trim(), holes: holes);
      await context.read<CourseProvider>().addCourse(course);
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'EDIT COURSE' : 'NEW COURSE')),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // AI lookup
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.green.withAlpha(12),
                      border: Border.all(color: AppColors.green.withAlpha(60)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.auto_awesome,
                                color: AppColors.gold, size: 18),
                            const SizedBox(width: 6),
                            Text('AI COURSE LOOKUP',
                                style: theme.textTheme.titleMedium
                                    ?.copyWith(color: AppColors.green)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _aiQueryCtrl,
                                decoration: const InputDecoration(
                                  hintText: 'e.g. Revere Henderson',
                                  prefixIcon: Icon(Icons.search),
                                  isDense: true,
                                ),
                                textCapitalization: TextCapitalization.words,
                                onSubmitted: (_) => _lookupWithAi(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _aiLoading ? null : _lookupWithAi,
                                child: _aiLoading
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.white,
                                        ),
                                      )
                                    : const Text('LOOK UP'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Course name
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Course Name',
                      prefixIcon: Icon(Icons.golf_course),
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Enter a course name'
                        : null,
                  ),
                  const SizedBox(height: 20),

                  // Hole count selector
                  TextFormField(
                    controller: _holeCountCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Number of Holes',
                      prefixIcon: Icon(Icons.pin),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (v) {
                      final n = int.tryParse(v);
                      if (n != null && n > 0) _setHoleCount(n);
                    },
                    validator: (v) {
                      final n = int.tryParse(v ?? '');
                      if (n == null || n <= 0) return 'Enter a valid number';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Par per hole
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('PAR PER HOLE', style: theme.textTheme.titleMedium),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.green,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'TOTAL PAR ${_pars.fold(0, (s, p) => s + p)}',
                          style: theme.textTheme.labelLarge
                              ?.copyWith(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _ParGrid(
                    pars: _pars,
                    onChanged: (i, par) => setState(() => _pars[i] = par),
                  ),
                ],
              ),
            ),

            // Save button
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_saving || _aiLoading) ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.white,
                          ),
                        )
                      : const Text('SAVE COURSE'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ParGrid extends StatelessWidget {
  final List<int> pars;
  final void Function(int index, int par) onChanged;

  const _ParGrid({required this.pars, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        childAspectRatio: 0.9,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
      ),
      itemCount: pars.length,
      itemBuilder: (ctx, i) => _ParCell(
        hole: i + 1,
        par: pars[i],
        onChanged: (par) => onChanged(i, par),
      ),
    );
  }
}

class _ParCell extends StatelessWidget {
  final int hole;
  final int par;
  final ValueChanged<int> onChanged;

  const _ParCell({
    required this.hole,
    required this.par,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => _showPicker(context),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          border: Border.all(color: AppColors.divider),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$hole',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textMuted,
                fontSize: 11,
              ),
            ),
            Text(
              '$par',
              style: theme.textTheme.titleLarge?.copyWith(
                color: AppColors.green,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Hole $hole — Select Par',
                style: Theme.of(ctx).textTheme.titleLarge),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [2, 3, 4, 5].map((p) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        par == p ? AppColors.gold : AppColors.green,
                    minimumSize: const Size(80, 60),
                  ),
                  onPressed: () {
                    onChanged(p);
                    Navigator.pop(ctx);
                  },
                  child: Text('Par $p',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700)),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
