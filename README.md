# Motus - Complete Car Maintenance Tracker

A comprehensive iOS app for tracking everything related to car maintenance, designed for meticulous record-keeping.

## Features

### 🚗 Vehicle Management
- Track multiple vehicles with detailed information
- Store VIN, license plate, mileage, engine type, and more
- View vehicle-specific statistics and history

### 🔧 Maintenance Tracking
- Detailed maintenance record entry
- Track service providers, technicians, and labor hours
- Parts association with maintenance records
- Warranty tracking for repairs
- Next service scheduling
- Cost breakdown (parts vs. labor)

### ⛽ Fuel Logging
- Track fuel purchases with price and location
- Automatic MPG calculations
- Fuel price trend charts
- Support for different fuel grades
- Full tank vs. partial fill tracking

### 🔩 Parts Inventory
- Comprehensive parts tracking with serial numbers
- Part categorization (engine, brakes, electrical, etc.)
- Warranty management
- Part condition tracking (new, OEM, aftermarket, etc.)
- Installation date and mileage tracking

### 📊 Analytics Dashboard
- Real-time cost summaries
- Fuel economy trends
- Maintenance spending analysis
- Recent activity timeline
- Visual charts and graphs

### ⏰ Service Reminders
- Mileage-based reminders
- Time-based reminders
- Combined mileage and time triggers
- Advance notification settings
- Due/approaching indicators

### 🤖 AI Manual Assistant
- Upload car manuals (PDF)
- Ask questions about your vehicle
- AI-powered responses
- Interactive chat interface
- Common maintenance queries

### 📄 Reporting & Export
- Generate detailed maintenance reports
- Fuel economy reports
- Complete vehicle reports
- Export as text files
- Share via system share sheet

## Technical Details

### Built With
- **SwiftUI** - Modern declarative UI framework
- **SwiftData** - Apple's latest data persistence framework
- **Charts** - Native charting framework for visualizations
- **Apple Intelligence** - AI-powered manual assistance (planned)

### Data Models
- `Vehicle` - Complete vehicle information with relationships
- `MaintenanceRecord` - Detailed service records
- `FuelLog` - Fuel purchases and economy tracking
- `Part` - Parts inventory with warranties
- `ServiceReminder` - Scheduled maintenance reminders

### Key Features
- Complete offline functionality
- Real-time MPG calculations
- Automatic mileage updates
- Warranty expiration tracking
- Service due detection
- Cost analysis and reporting

## Target User

Designed for users who need meticulous record-keeping, such as:
- Military/Air Force mechanics maintaining personal vehicles
- Fleet managers
- Car enthusiasts
- Anyone who values detailed maintenance history

## Requirements

- iOS 17.0+
- Xcode 15.0+
- SwiftUI framework
- SwiftData framework

## Installation

1. Clone the repository
2. Open `Motus.xcodeproj` in Xcode
3. Build and run on your iOS device or simulator

## Usage

### Adding Your First Vehicle
1. Launch the app
2. Tap "Add Your First Vehicle" on the dashboard
3. Fill in vehicle details (make, model, year, VIN, etc.)
4. Save to start tracking

### Logging Maintenance
1. Go to the Maintenance tab
2. Tap the + button
3. Select vehicle and service type
4. Enter details including cost, mileage, and parts used
5. Optionally set next service date/mileage

### Tracking Fuel
1. Navigate to the Fuel tab
2. Add a new fuel log
3. Enter gallons, price, and location
4. App automatically calculates MPG based on previous fill-ups

### Managing Parts
1. Open the Parts tab
2. Add parts with serial numbers and warranties
3. Track installation dates and costs
4. Associate parts with maintenance records

### Setting Reminders
1. Go to Dashboard or create from vehicle detail
2. Add service reminder
3. Set mileage and/or time-based triggers
4. Get notified when service is due or approaching

### Using AI Assistant
1. Navigate to AI Assistant tab
2. Select your vehicle
3. Upload car manual (PDF) - optional
4. Ask questions about maintenance procedures
5. Get AI-powered responses

### Generating Reports
1. Open vehicle detail view
2. Access reports section
3. Choose report type (maintenance, fuel, or complete)
4. Generate and share via email, messages, etc.

## Future Enhancements

- [ ] Full Apple Intelligence integration with car manuals
- [ ] CoreML-powered document understanding
- [ ] PDF report generation
- [ ] Photo attachments for records
- [ ] Cloud sync via iCloud
- [ ] Widget support
- [ ] Apple Watch companion app
- [ ] Siri shortcuts
- [ ] Push notifications for reminders

## Architecture

The app follows modern iOS development practices:
- MVVM architecture with SwiftUI
- SwiftData for persistence
- Modular view structure
- Reusable components
- Type-safe data models

## File Structure

```
Motus/
├── Models/
│   ├── Vehicle.swift
│   ├── MaintenanceRecord.swift
│   ├── FuelLog.swift
│   ├── Part.swift
│   └── ServiceReminder.swift
├── Views/
│   ├── Dashboard/
│   ├── Vehicles/
│   ├── Maintenance/
│   ├── Fuel/
│   ├── Parts/
│   ├── Reminders/
│   ├── AI/
│   └── Reports/
├── Utilities/
│   └── ReportGenerator.swift
└── ContentView.swift
```

## Contributing

This is a personal project, but suggestions and feedback are welcome!

## License

All rights reserved.

## Author

Kevin Hamby

## Acknowledgments

- Built with SwiftUI and SwiftData
- Uses Apple's Charts framework
- Designed for iOS 17+
