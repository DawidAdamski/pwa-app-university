const fs = require('fs');
const path = require('path');

// Create a simple SVG icon generator
function createSVGIcon(size, color = '#2196F3') {
    return `<svg width="${size}" height="${size}" viewBox="0 0 ${size} ${size}" xmlns="http://www.w3.org/2000/svg">
        <rect width="${size}" height="${size}" fill="${color}" rx="${size/8}"/>
        <text x="50%" y="50%" font-family="Arial, sans-serif" font-size="${size/3}" font-weight="bold" text-anchor="middle" dominant-baseline="middle" fill="white">🧠</text>
    </svg>`;
}

// Icon sizes needed for PWA
const iconSizes = [16, 32, 72, 96, 128, 144, 152, 192, 384, 512];

// Create icons directory if it doesn't exist
const iconsDir = path.join(__dirname, 'icons');
if (!fs.existsSync(iconsDir)) {
    fs.mkdirSync(iconsDir, { recursive: true });
}

// Generate SVG icons
iconSizes.forEach(size => {
    const svgContent = createSVGIcon(size);
    const filename = `icon-${size}x${size}.svg`;
    fs.writeFileSync(path.join(iconsDir, filename), svgContent);
    console.log(`Created ${filename}`);
});

// Create a simple HTML file to convert SVG to PNG (for demonstration)
const converterHTML = `<!DOCTYPE html>
<html>
<head>
    <title>Icon Converter</title>
</head>
<body>
    <h1>Icon Converter</h1>
    <p>This is a placeholder for icon conversion. In a real project, you would use tools like:</p>
    <ul>
        <li>ImageMagick</li>
        <li>Sharp (Node.js library)</li>
        <li>Online converters</li>
        <li>Design tools like Figma, Sketch, or Adobe Illustrator</li>
    </ul>
    <p>For now, the SVG icons will work in most browsers for PWA purposes.</p>
</body>
</html>`;

fs.writeFileSync(path.join(__dirname, 'icon-converter.html'), converterHTML);
console.log('Created icon-converter.html for reference');

console.log('\nIcon generation complete!');
console.log('Note: For production, convert SVG icons to PNG format using image conversion tools.');
