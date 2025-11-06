# OldSTL - Historical St. Louis Photos

An interactive map application that displays historical photographs of St. Louis at their geographical locations, inspired by [OldSF.org](https://www.oldsf.org/).

## About This Project

This site provides an alternative way of browsing the incredible historical photograph collections from the [St. Louis Public Library](https://www.slpl.org/) and the [Missouri Historical Society](https://mohistory.org/). Its goal is to help you discover the history behind the places you see every day in St. Louis.

By placing historical images on an interactive map, you can explore how the Gateway City has changed over time, right where those changes happened.

## Features

- **Interactive Leaflet Map**: Explore St. Louis with an intuitive, zoomable map interface
- **Historical Photo Markers**: Purple circular markers indicate locations of historical photos
- **Active Marker Highlight**: Clicked markers glow green and pulse to show current selection
- **Collapsible Time Period Filter**: Dropdown slider to filter photos by decade (1850-2000)
- **Side Panel Display**: Toggle panel showing all photos at selected location
- **Smart Map Panning**: Map automatically shifts to keep selected markers visible
- **Full-Size Modal Viewer**: Click any photo to view it in full resolution
- **About Page**: Built-in information about the project
- **Responsive Design**: Works seamlessly on desktop, tablet, and mobile devices

## Project Structure

```text
OldSTL/
├── index.html          # Main HTML file
├── styles.css          # All styling and responsive design
├── app.js              # JavaScript for map and interactivity
├── StlLocations.json   # Photo data in JSON format
├── README.md           # This file
└── .github/
    └── copilot-instructions.md
```

## Getting Started

### Prerequisites

- A modern web browser (Chrome, Firefox, Safari, Edge)
- VS Code with Live Server extension (recommended)

### Installation

1. Clone or download this repository
2. Open the project folder in VS Code
3. Right-click on `index.html` and select "Open with Live Server"
4. The application will open in your default browser

### Alternative: Direct File Opening

Simply open `index.html` in any web browser. All dependencies are loaded via CDN.

## Usage

1. **Browse the Map**: Pan and zoom to explore different areas of St. Louis
2. **Toggle Side Panel**: Click the arrow button (◄/►) in the top-right to open/close the photo panel
3. **Filter by Time**: Click the year range "1850–2000 ▼" to expand the time slider and filter photos by decade
4. **Click Markers**: Click on any purple marker to view photos at that location
   - The marker will glow green and pulse when selected
   - The side panel opens automatically with all photos at that location
   - The map shifts to keep the marker visible
5. **View Full Size**: Click on any photo in the side panel to open the full-size modal viewer
6. **About**: Click the "About" link in the side panel footer to learn more about the project
7. **Close Modal**: Click the X, press Escape, or click outside the image

## Technologies Used

- **Leaflet.js** (v1.9.4): Open-source JavaScript library for interactive maps
- **OpenStreetMap**: Free, editable map tiles
- **Vanilla JavaScript**: No framework dependencies, async JSON loading
- **CSS3**: Modern styling with flexbox, animations, and transitions
- **HTML5**: Semantic markup

## Customization

### Adding Your Own Photos

Edit the `StlLocations.json` file to add new photos:

```json
{
    "id": 11,
    "title": "Your Photo Title",
    "year": 1950,
    "lat": 38.6270,
    "lng": -90.1994,
    "thumbnail": "path/to/thumbnail.jpg",
    "fullImage": "path/to/full-image.jpg",
    "description": "Photo description"
}
```

**Note**: Photos with identical coordinates (within 0.001 degrees tolerance) will be grouped together in the side panel.

### Changing Map Center & Zoom

In `app.js`, modify the map initialization:

```javascript
const map = L.map('map').setView([latitude, longitude], zoomLevel);
```

### Customizing Colors

Edit the CSS variables and colors in `styles.css`:

- Header gradient: `background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);`
- Marker color: `.custom-marker { background-color: #667eea; }`
- Active marker color: `.custom-marker.active { background-color: #10b981; }`
- Link colors: Various purple shades (#667eea)

## Key Features Breakdown

### Side Panel

- **Toggle Button**: Arrow icon (◄/►) positioned in top-right corner
- **Collapsible**: Click toggle or X button to open/close
- **Dynamic Content**: Shows photos for clicked location or About page
- **Auto-open**: Opens automatically when marker is clicked
- **Scrollable**: Panel content scrolls independently

### Time Filtering

- **Collapsible Slider**: Click year range to expand/collapse dual-range slider
- **Real-time Updates**: Markers update as you adjust the time range
- **Year Display**: Shows current range (e.g., "1850–2000")
- **Visual Feedback**: Arrow indicates dropdown state (▼/▲)

### Marker Interaction

- **Click Feedback**: Markers turn green and pulse when selected
- **Smart Panning**: Map automatically shifts right to keep clicked marker visible
- **State Tracking**: Only one marker can be active at a time
- **Hover Effect**: Markers scale up on hover

### Data Management

- **JSON-based**: All photo data stored in `StlLocations.json`
- **Async Loading**: Data fetched asynchronously on page load
- **Location Grouping**: Photos at same coordinates displayed together
- **Easy Updates**: Add/edit photos without touching JavaScript code

## Improvements Over Basic OldSF Clone

✅ Collapsible time filter instead of always-visible dropdown

✅ Side panel with toggle instead of always-on-screen popups

✅ Active marker highlighting (green glow with pulse animation)

✅ Smart map panning to keep markers visible when panel opens

✅ JSON-based data structure for easier maintenance

✅ About page integrated into side panel

✅ Responsive arrow icons for panel state

✅ No popups - cleaner marker interaction

## Browser Support

- Chrome 90+
- Firefox 88+
- Safari 14+
- Edge 90+

## Future Enhancements

- Connect to a real database or API for photo data
- Add photo upload functionality
- Implement search by location or keyword
- Add street view comparison feature
- Include historical narratives and stories
- User authentication and favorites
- Clustering for locations with many photos
- Share/permalink functionality

## License

This project is open source and available for educational purposes.

## Credits

- Map tiles by [OpenStreetMap](https://www.openstreetmap.org/)
- Map library by [Leaflet](https://leafletjs.com/)
- Historical photographs courtesy of:
  - [St. Louis Public Library](https://www.slpl.org/) - Digital Collections
  - [Missouri Historical Society](https://mohistory.org/) - Research Library & Archives
- Placeholder images from [Unsplash](https://unsplash.com/)
- Inspired by [OldSF.org](https://www.oldsf.org/)

## Contributing

Feel free to fork this project and add your own historical photos of St. Louis or adapt it for your own city!

---

**Note**: The current implementation uses placeholder images from Unsplash. Replace these with actual historical St. Louis photos for production use.
