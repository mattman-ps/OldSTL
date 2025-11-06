// Historical photos data - loaded from JSON file
let historicalPhotos = [];
let minYearInData = 1850;
let maxYearInData = 2000;

// Helper functions to extract data from new format
const getYear = (photo) => {
    if (photo.extracted && photo.extracted.date_range && photo.extracted.date_range[0]) {
        return parseInt(photo.extracted.date_range[0].substring(0, 4));
    }
    return parseInt(photo.date) || 1900;
};

const getLatLng = (photo) => {
    if (photo.extracted && photo.extracted.latlon) {
        return {
            lat: photo.extracted.latlon[0],
            lng: photo.extracted.latlon[1]
        };
    }
    return { lat: 0, lng: 0 };
};

const getThumbnail = (photo) => {
    return photo.url ? photo.url.replace('w=1200', 'w=400') : '';
};

const getFullImage = (photo) => {
    return photo.url || '';
};

const getDescription = (photo) => {
    return photo.note || photo.description || '';
};

// Initialize the map
const map = L.map('map').setView([38.6270, -90.1994], 12);

// Add OpenStreetMap tile layer
L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
    attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors',
    maxZoom: 19
}).addTo(map);

// Store all markers and track active marker
let markers = [];
let activeMarker = null;

// Create custom icon
const createCustomIcon = (isActive = false, count = null) => {
    const html = count !== null ? `<div class="marker-count">${count}</div>` : '';
    return L.divIcon({
        className: isActive ? 'custom-marker active' : 'custom-marker',
        html: html,
        iconSize: [30, 30],
        iconAnchor: [15, 15],
        popupAnchor: [0, -15]
    });
};

// Create popup content
const createPopupContent = (photo) => {
    return `
        <div class="popup-content">
            <img src="${photo.thumbnail}"
                 alt="${photo.title}"
                 class="popup-image"
                 onclick="openSidePanelById(${photo.id})">
            <div class="popup-info">
                <div class="popup-title">${photo.title}</div>
                <div class="popup-year">${photo.year}</div>
                <div class="popup-description">${photo.description}</div>
                <a href="#" class="popup-link" onclick="openSidePanelById(${photo.id}); return false;">
                    View All Photos
                </a>
            </div>
        </div>
    `;
};

// Add markers to map
const addMarkers = (photos) => {
    // Clear existing markers
    markers.forEach(marker => map.removeLayer(marker));
    markers = [];
    activeMarker = null;

    // Add new markers
    photos.forEach(photo => {
        const coords = getLatLng(photo);
        const marker = L.marker([coords.lat, coords.lng], {
            icon: createCustomIcon(false)
        })
            .on('click', function(e) {
                // Find all photos at this location
                const tolerance = 0.001;
                const photosAtLocation = photos.filter(p => {
                    const pCoords = getLatLng(p);
                    const latMatch = Math.abs(pCoords.lat - coords.lat) < tolerance;
                    const lngMatch = Math.abs(pCoords.lng - coords.lng) < tolerance;
                    return latMatch && lngMatch;
                });

                const photoCount = photosAtLocation.length;

                // Reset previous active marker
                if (activeMarker) {
                    activeMarker.setIcon(createCustomIcon(false));
                }

                // Set this marker as active with count
                activeMarker = marker;
                marker.setIcon(createCustomIcon(true, photoCount));

                // When marker is clicked, load photos for that location
                openSidePanelById(photo.id);
            })
            .addTo(map);

        markers.push(marker);
    });

    // Update photo count
    updatePhotoCount(photos.length);
};// Filter photos by year range
const filterPhotosByYearRange = (minYear, maxYear) => {
    return historicalPhotos.filter(photo => {
        const year = getYear(photo);
        return year >= minYear && year <= maxYear;
    });
};

// Update year range display
const updateYearDisplay = (minYear, maxYear) => {
    const yearRange = document.getElementById('yearRange');
    const sliderPanel = document.getElementById('sliderPanel');
    const arrow = sliderPanel.classList.contains('open') ? '▲' : '▼';
    yearRange.textContent = `${minYear}–${maxYear} ${arrow}`;
};

// Toggle slider panel
const filterToggle = document.getElementById('filterToggle');
const sliderPanel = document.getElementById('sliderPanel');

filterToggle.addEventListener('click', () => {
    sliderPanel.classList.toggle('open');
    updateYearDisplay(parseInt(minYearSlider.value), parseInt(maxYearSlider.value));
});

// Update photo count display
const updatePhotoCount = (count) => {
    const photoCount = document.getElementById('photoCount');
    photoCount.textContent = `Showing ${count} historical photo${count !== 1 ? 's' : ''}`;
};

// Slider event handlers
const minYearSlider = document.getElementById('minYear');
const maxYearSlider = document.getElementById('maxYear');

// Update the colored fill between slider thumbs
const updateSliderFill = () => {
    const min = parseInt(minYearSlider.value);
    const max = parseInt(maxYearSlider.value);
    const minPercent = ((min - minYearInData) / (maxYearInData - minYearInData)) * 100;
    const maxPercent = ((max - minYearInData) / (maxYearInData - minYearInData)) * 100;

    const sliderContainer = document.getElementById('sliderPanel');
    sliderContainer.style.setProperty('--min-percent', `${minPercent}%`);
    sliderContainer.style.setProperty('--max-percent', `${maxPercent}%`);
};

const updateFilter = () => {
    let minYear = parseInt(minYearSlider.value);
    let maxYear = parseInt(maxYearSlider.value);

    // Ensure min is always less than or equal to max
    if (minYear > maxYear) {
        [minYear, maxYear] = [maxYear, minYear];
        minYearSlider.value = minYear;
        maxYearSlider.value = maxYear;
    }

    updateSliderFill();
    updateYearDisplay(minYear, maxYear);
    const filteredPhotos = filterPhotosByYearRange(minYear, maxYear);
    addMarkers(filteredPhotos);
};

minYearSlider.addEventListener('input', updateFilter);
maxYearSlider.addEventListener('input', updateFilter);

// Modal functionality
const modal = document.getElementById('photoModal');
const modalImage = document.getElementById('modalImage');
const modalTitle = document.getElementById('modalTitle');
const modalDescription = document.getElementById('modalDescription');
const modalYear = document.getElementById('modalYear');
const closeBtn = document.querySelector('.close');

// Side Panel functionality
const sidePanel = document.getElementById('sidePanel');
const panelContent = document.getElementById('panelContent');
const closePanel = document.getElementById('closePanel');
const aboutLink = document.getElementById('aboutLink');
const panelToggle = document.getElementById('panelToggle');

// Toggle side panel
panelToggle.addEventListener('click', () => {
    const isOpen = sidePanel.classList.toggle('open');
    panelToggle.classList.toggle('panel-open', isOpen);

    // Update arrow direction
    panelToggle.textContent = isOpen ? '►' : '◄';

    // If opening and no content, show default message
    if (isOpen && !panelContent.innerHTML.trim()) {
        panelContent.innerHTML = `
            <div class="about-content">
                <h2>Welcome to OldSTL</h2>
                <p>Click on any purple marker on the map to view historical photos at that location.</p>
                <p>Or click the "About" link below to learn more about this project.</p>
            </div>
        `;
    }
});

// Open side panel with photos for a location by photo ID
window.openSidePanelById = (photoId) => {
    const photo = historicalPhotos.find(p => p.id === photoId);
    if (!photo) {
        console.error('Photo not found:', photoId);
        return;
    }

    console.log('Opening side panel for photo:', photo);

    // Find all photos at this location (with tolerance for coordinate matching)
    const tolerance = 0.001;
    const coords = getLatLng(photo);
    const photosAtLocation = historicalPhotos.filter(p => {
        const pCoords = getLatLng(p);
        const latMatch = Math.abs(pCoords.lat - coords.lat) < tolerance;
        const lngMatch = Math.abs(pCoords.lng - coords.lng) < tolerance;
        return latMatch && lngMatch;
    });

    console.log('Photos at location:', photosAtLocation);

    const photoCount = photosAtLocation.length;

    // Sort photos by year (oldest to newest)
    photosAtLocation.sort((a, b) => getYear(a) - getYear(b));

    // Find and update the marker for this location
    markers.forEach(marker => {
        const markerLatLng = marker.getLatLng();
        const latMatch = Math.abs(markerLatLng.lat - coords.lat) < tolerance;
        const lngMatch = Math.abs(markerLatLng.lng - coords.lng) < tolerance;

        if (latMatch && lngMatch) {
            // Reset previous active marker
            if (activeMarker && activeMarker !== marker) {
                activeMarker.setIcon(createCustomIcon(false));
            }

            // Set this marker as active with count
            activeMarker = marker;
            marker.setIcon(createCustomIcon(true, photoCount));
        }
    });

    // Build panel content
    const folderName = photo.folder || 'Historical Photos';
    let content = `<div class="location-header">${folderName}</div>`;

    photosAtLocation.forEach(p => {
        const thumbnail = getThumbnail(p);
        const description = getDescription(p);
        const year = getYear(p);

        content += `
            <div class="photo-item" onclick="openModal('${p.id}')">
                <img src="${thumbnail}" alt="${p.title}">
                <div class="photo-item-info">
                    <div class="photo-item-title">${p.title}</div>
                    <div class="photo-item-year">${p.date || year}</div>
                    <div class="photo-item-description">${description}</div>
                </div>
            </div>
        `;
    });

    console.log('Content HTML length:', content.length);

    panelContent.innerHTML = content;

    // Open the panel if it's not already open
    const wasOpen = sidePanel.classList.contains('open');
    if (!wasOpen) {
        sidePanel.classList.add('open');
        panelToggle.classList.add('panel-open');
        panelToggle.textContent = '►';
    }

    // Always pan the map to ensure the marker is visible
    // Center on the marker with offset to account for the panel
    const markerLatLng = L.latLng(coords.lat, coords.lng);

    // Calculate offset (400px panel width / 2 = 200px offset)
    // Convert pixels to map coordinates
    const point = map.latLngToContainerPoint(markerLatLng);
    point.x += 200; // Shift right by half the panel width
    const newCenter = map.containerPointToLatLng(point);

    // Smoothly pan to the new center
    map.panTo(newCenter, { animate: true, duration: 0.5 });
};

// Close side panel
closePanel.addEventListener('click', () => {
    sidePanel.classList.remove('open');
    panelToggle.classList.remove('panel-open');
    panelToggle.textContent = '◄';
});

// Show About page
aboutLink.addEventListener('click', (e) => {
    e.preventDefault();
    const aboutContent = `
        <div class="about-content">
            <h2>About OldSTL</h2>
            <p>
                OldSTL is an interactive map showcasing historical photographs of St. Louis, Missouri.
                Explore the rich history of this iconic American city through vintage images placed at
                their exact geographical locations.
            </p>
            <p>
                This project is inspired by <a href="https://www.oldsf.org/" target="_blank">OldSF.org</a>,
                which provides a similar experience for San Francisco historical photos.
            </p>
            <h2>How to Use</h2>
            <p>
                <strong>Browse the Map:</strong> Pan and zoom to explore different areas of St. Louis.
            </p>
            <p>
                <strong>Filter by Time:</strong> Click the year range to open a slider and filter photos by decade.
            </p>
            <p>
                <strong>View Photos:</strong> Click on any purple marker to see all photos at that location in this side panel.
            </p>
            <p>
                <strong>Full Size View:</strong> Click on any photo to view it in full resolution.
            </p>
            <h2>Technology</h2>
            <p>
                Built with <a href="https://leafletjs.com/" target="_blank">Leaflet.js</a> for interactive maps
                and <a href="https://www.openstreetmap.org/" target="_blank">OpenStreetMap</a> tiles.
            </p>
            <h2>Credits</h2>
            <p>
                Placeholder images provided by <a href="https://unsplash.com/" target="_blank">Unsplash</a>.
                Replace with actual historical St. Louis photos for production use.
            </p>
        </div>
    `;
    panelContent.innerHTML = aboutContent;
    if (!sidePanel.classList.contains('open')) {
        sidePanel.classList.add('open');
        panelToggle.classList.add('panel-open');
        panelToggle.textContent = '►';
    }
});

// Open modal function (accessible globally)
window.openModal = (photoId) => {
    const photo = historicalPhotos.find(p => p.id === photoId);
    if (photo) {
        modalImage.src = getFullImage(photo);
        modalTitle.textContent = photo.title;
        modalDescription.textContent = getDescription(photo);
        modalYear.textContent = `Year: ${photo.date || getYear(photo)}`;
        modal.style.display = 'block';
    }
};

// Close modal
closeBtn.onclick = () => {
    modal.style.display = 'none';
};

// Close modal when clicking outside
window.onclick = (event) => {
    if (event.target === modal) {
        modal.style.display = 'none';
    }
};

// Close modal with Escape key
document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape' && modal.style.display === 'block') {
        modal.style.display = 'none';
    }
});

// Load locations from JSON file and initialize the map
async function loadLocations() {
    try {
        const response = await fetch('src/data/locations.json');
        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }
        historicalPhotos = await response.json();

        // Calculate min and max years from the data
        if (historicalPhotos.length > 0) {
            const years = historicalPhotos.map(p => getYear(p));
            minYearInData = Math.min(...years);
            maxYearInData = Math.max(...years);

            // Update slider attributes
            minYearSlider.min = minYearInData;
            minYearSlider.max = maxYearInData;
            minYearSlider.value = minYearInData;
            maxYearSlider.min = minYearInData;
            maxYearSlider.max = maxYearInData;
            maxYearSlider.value = maxYearInData;

            // Round to nearest decade for step
            const yearRange = maxYearInData - minYearInData;
            const step = yearRange > 100 ? 10 : 5;
            minYearSlider.step = step;
            maxYearSlider.step = step;
        }

        addMarkers(historicalPhotos);
        // Initialize the year display with arrow
        updateYearDisplay(minYearInData, maxYearInData);
        // Initialize slider fill
        updateSliderFill();

        // Default to first photo on load
        if (historicalPhotos.length > 0) {
            openSidePanelById(historicalPhotos[0].id);
        }
    } catch (error) {
        console.error('Error loading locations:', error);
        document.getElementById('photoCount').textContent = 'Error loading photos. Please refresh the page.';
    }
}

// Initialize the application
loadLocations();
