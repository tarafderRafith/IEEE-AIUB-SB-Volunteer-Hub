import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/database_service.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() =>
      _CreateEventScreenState();
}

class _CreateEventScreenState
    extends State<CreateEventScreen> {
  final _formKey =
      GlobalKey<FormState>();

  final _titleController =
      TextEditingController();

  final _descriptionController =
      TextEditingController();

  final _locationController =
      TextEditingController();

  final _organizerController =
      TextEditingController();

  final List<String> _eventTypes = [
    'Workshop',
    'Seminar',
    'Competition',
    'Meeting',
    'Campaign',
    'Social',
    'Other',
  ];

  String _selectedEventType =
      'Workshop';

  DateTime? _selectedDate;

  TimeOfDay? _selectedTime;

  bool _isCreating = false;

  @override
  void initState() {
    super.initState();

    _organizerController.text =
        AuthService.fullName ?? '';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _organizerController.dispose();

    super.dispose();
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();

    final date = await showDatePicker(
      context: context,
      initialDate:
          _selectedDate ?? now,
      firstDate: now,
      lastDate:
          DateTime(now.year + 5),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme:
                const ColorScheme.dark(
              primary: Color(0xFF0D5BD7),
              surface: Color(0xFF0A2348),
            ),
          ),
          child: child!,
        );
      },
    );

    if (date == null) {
      return;
    }

    setState(() {
      _selectedDate = date;
    });
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime:
          _selectedTime ??
          TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme:
                const ColorScheme.dark(
              primary: Color(0xFF0D5BD7),
              surface: Color(0xFF0A2348),
            ),
          ),
          child: child!,
        );
      },
    );

    if (time == null) {
      return;
    }

    setState(() {
      _selectedTime = time;
    });
  }

  String _formatDate(
    DateTime date,
  ) {
    final day =
        date.day.toString().padLeft(2, '0');

    final month =
        date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  String _formatTime(
    TimeOfDay time,
  ) {
    final hour =
        time.hourOfPeriod == 0
            ? 12
            : time.hourOfPeriod;

    final minute =
        time.minute.toString().padLeft(2, '0');

    final period =
        time.period == DayPeriod.am
            ? 'AM'
            : 'PM';

    return '$hour:$minute $period';
  }

  Future<void> _createEvent() async {
    if (!_formKey.currentState!
        .validate()) {
      return;
    }

    if (_selectedDate == null) {
      _showError(
        'Please select an event date.',
      );
      return;
    }

    if (_selectedTime == null) {
      _showError(
        'Please select an event time.',
      );
      return;
    }

    final memberId =
        AuthService.memberId;

    if (memberId == null ||
        memberId.isEmpty) {
      _showError(
        'Executive account information is missing.',
      );
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      final eventId =
          await DatabaseService.createEvent(
        title:
            _titleController.text.trim(),
        description:
            _descriptionController.text.trim(),
        date: _selectedDate!
            .toIso8601String(),
        time: _selectedTime!
            .format(context),
        location:
            _locationController.text.trim(),
        eventType:
            _selectedEventType,
        organizer:
            _organizerController.text.trim(),
        createdByMemberId: memberId,
      );

      if (!mounted) return;

      setState(() {
        _isCreating = false;
      });

      if (eventId <= 0) {
        _showError(
          'Failed to create the event.',
        );
        return;
      }

      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor:
                const Color(0xFF0A2348),
            shape:
                RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(22),
            ),
            title: const Row(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color:
                      Color(0xFF55D88A),
                ),
                SizedBox(width: 10),
                Text(
                  'Event Created',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ],
            ),
            content: const Text(
              'The event has been successfully added to the branch event list.',
              style: TextStyle(
                color: Colors.white70,
                height: 1.5,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text(
                  'DONE',
                  style: TextStyle(
                    color:
                        Color(0xFF6EA6FF),
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ),
            ],
          );
        },
      );

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      debugPrint(
        'Create event error: $e',
      );

      if (!mounted) return;

      setState(() {
        _isCreating = false;
      });

      _showError(
        'Something went wrong while creating the event.',
      );
    }
  }

  void _showError(
    String message,
  ) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            const Color(0xFFB3261E),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFF041329),
      appBar: AppBar(
        backgroundColor:
            const Color(0xFF041329),
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Colors.white,
          ),
        ),
        title: const Text(
          'Create Event',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.fromLTRB(
              20,
              10,
              20,
              35,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                _buildHeader(),

                const SizedBox(height: 25),

                _sectionTitle(
                  'EVENT INFORMATION',
                ),

                const SizedBox(height: 12),

                _inputField(
                  controller:
                      _titleController,
                  label: 'Event Title',
                  hint:
                      'Enter event title',
                  icon:
                      Icons.event_rounded,
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Event title is required';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 14),

                _inputField(
                  controller:
                      _descriptionController,
                  label: 'Description',
                  hint:
                      'Describe the event',
                  icon:
                      Icons.description_outlined,
                  maxLines: 5,
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Description is required';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 14),

                _buildEventType(),

                const SizedBox(height: 25),

                _sectionTitle(
                  'DATE & TIME',
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _dateTimeCard(
                        icon:
                            Icons.calendar_month_rounded,
                        title: 'Date',
                        value:
                            _selectedDate ==
                                    null
                                ? 'Select date'
                                : _formatDate(
                                    _selectedDate!,
                                  ),
                        onTap:
                            _selectDate,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _dateTimeCard(
                        icon:
                            Icons.access_time_rounded,
                        title: 'Time',
                        value:
                            _selectedTime ==
                                    null
                                ? 'Select time'
                                : _formatTime(
                                    _selectedTime!,
                                  ),
                        onTap:
                            _selectTime,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 25),

                _sectionTitle(
                  'LOCATION & ORGANIZER',
                ),

                const SizedBox(height: 12),

                _inputField(
                  controller:
                      _locationController,
                  label: 'Location',
                  hint:
                      'Example: Multipurpose Hall',
                  icon:
                      Icons.location_on_outlined,
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Location is required';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 14),

                _inputField(
                  controller:
                      _organizerController,
                  label: 'Organizer',
                  hint:
                      'Event organizer',
                  icon:
                      Icons.person_outline_rounded,
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Organizer is required';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  height: 57,
                  child: ElevatedButton(
                    onPressed:
                        _isCreating
                            ? null
                            : _createEvent,
                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(
                        0xFF0D5BD7,
                      ),
                      disabledBackgroundColor:
                          const Color(
                        0xFF0D5BD7,
                      ).withOpacity(0.45),
                      foregroundColor:
                          Colors.white,
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          17,
                        ),
                      ),
                    ),
                    child: _isCreating
                        ? const SizedBox(
                            width: 23,
                            height: 23,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color:
                                  Colors.white,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment:
                                MainAxisAlignment
                                    .center,
                            children: [
                              Icon(
                                Icons
                                    .add_circle_outline_rounded,
                                size: 21,
                              ),
                              SizedBox(width: 9),
                              Text(
                                'CREATE EVENT',
                                style:
                                    TextStyle(
                                  fontSize: 13,
                                  fontWeight:
                                      FontWeight.w800,
                                  letterSpacing:
                                      0.8,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(21),
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(23),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0D5BD7),
            Color(0xFF08295F),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.event_available_rounded,
            color: Colors.white,
            size: 38,
          ),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Create a Branch Event',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Add an upcoming event for volunteers and executives.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(
    String title,
  ) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFF6EA6FF),
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.3,
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required String? Function(String?)
        validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 13,
      ),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Padding(
          padding:
              const EdgeInsets.only(
            left: 12,
            right: 8,
          ),
          child: Icon(
            icon,
            color: const Color(0xFF4D91FF),
            size: 20,
          ),
        ),
        filled: true,
        fillColor: const Color(0xFF0A2348),
        labelStyle: const TextStyle(
          color: Colors.white54,
          fontSize: 12,
        ),
        hintStyle: const TextStyle(
          color: Colors.white30,
          fontSize: 12,
        ),
        prefixIconConstraints:
            const BoxConstraints(
          minWidth: 48,
        ),
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Colors.white
                .withOpacity(0.05),
          ),
        ),
        focusedBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(16),
          borderSide:
              const BorderSide(
            color: Color(0xFF3D8BFF),
            width: 1.2,
          ),
        ),
        errorBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(16),
          borderSide:
              const BorderSide(
            color: Color(0xFFFF6B6B),
          ),
        ),
        focusedErrorBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(16),
          borderSide:
              const BorderSide(
            color: Color(0xFFFF6B6B),
          ),
        ),
      ),
    );
  }

  Widget _buildEventType() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF0A2348),
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white
              .withOpacity(0.05),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedEventType,
          isExpanded: true,
          dropdownColor:
              const Color(0xFF0A2348),
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Color(0xFF4D91FF),
          ),
          items: _eventTypes
              .map(
                (type) =>
                    DropdownMenuItem<String>(
                  value: type,
                  child: Text(
                    type,
                    style:
                        const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value == null) return;

            setState(() {
              _selectedEventType = value;
            });
          },
        ),
      ),
    );
  }

  Widget _dateTimeCard({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(16),
        child: Ink(
          padding:
              const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: const Color(0xFF0A2348),
            borderRadius:
                BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white10,
            ),
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                color: const Color(0xFF4D91FF),
                size: 22,
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 9,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                maxLines: 1,
                overflow:
                    TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}