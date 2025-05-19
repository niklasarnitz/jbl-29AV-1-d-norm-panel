// Panel dimensions
width = 57;    // mm
height = 57;   // mm
depth = 3;     // mm
corner_radius = 6; // mm

// Hole parameters
hole_diameter = 4;     // mm
hole_edge_distance = 6.5;   // mm from edge of panel to center of hole
countersink_diameter = 6;   // mm
countersink_depth = 1.5;      // mm

// Sunken rectangle parameters
rect_width = 38;  // mm
rect_height = 31; // mm
rect_depth = 5;   // mm
rect_corner_radius = 1; // mm

// Neutrik D-Norm Speakon connector parameters
speakon_diameter = 24;      // mm (main connector hole)
speakon_mount_diameter = 3.2;  // mm (mounting holes)
speakon_mount_distance = 24;   // mm (distance between mounting holes centers)

// Create the rounded square panel
module rounded_square(size_x, size_y, radius) {
    // Calculate the position adjustments for the corners
    x_adj = size_x/2 - radius;
    y_adj = size_y/2 - radius;

    hull() {
        // Place circles at the four corners
        translate([ x_adj,  y_adj, 0]) circle(r=radius);
        translate([-x_adj,  y_adj, 0]) circle(r=radius);
        translate([ x_adj, -y_adj, 0]) circle(r=radius);
        translate([-x_adj, -y_adj, 0]) circle(r=radius);
    }
}

// Create the 3D panel by extruding the 2D shape and creating a recessed area
difference() {
    union() {
        // Base panel with holes
        difference() {
            linear_extrude(height=depth) {
                difference() {
                    // Base panel
                    rounded_square(width, height, corner_radius);

                    // Holes at each corner
                    translate([ width/2-hole_edge_distance,  height/2-hole_edge_distance, -1]) circle(d=hole_diameter);
                    translate([-width/2+hole_edge_distance,  height/2-hole_edge_distance, -1]) circle(d=hole_diameter);
                    translate([ width/2-hole_edge_distance, -height/2+hole_edge_distance, -1]) circle(d=hole_diameter);
                    translate([-width/2+hole_edge_distance, -height/2+hole_edge_distance, -1]) circle(d=hole_diameter);
                }
            }

            // Sunken rectangle in the middle with rounded corners
            translate([0, 0, depth-rect_depth]) {
                linear_extrude(height=rect_depth) {
                    rounded_square(rect_width, rect_height, rect_corner_radius);
                }
            }

            // Countersinks for the corner holes
            translate([ width/2-hole_edge_distance,  height/2-hole_edge_distance, depth-countersink_depth]) cylinder(h=countersink_depth+1, d=countersink_diameter, $fn=100);
            translate([-width/2+hole_edge_distance,  height/2-hole_edge_distance, depth-countersink_depth]) cylinder(h=countersink_depth+1, d=countersink_diameter, $fn=100);
            translate([ width/2-hole_edge_distance, -height/2+hole_edge_distance, depth-countersink_depth]) cylinder(h=countersink_depth+1, d=countersink_diameter, $fn=100);
            translate([-width/2+hole_edge_distance, -height/2+hole_edge_distance, depth-countersink_depth]) cylinder(h=countersink_depth+1, d=countersink_diameter, $fn=100);
        }

        // Base extension under the sunken area
        difference() {
            translate([0, 0, -2]) {
                linear_extrude(height=2) {
                    rounded_square(rect_width, rect_height, rect_corner_radius);
                }
            }
        }
    }

    // Speakon connector cutouts - cut through the entire model at once
    // Main center hole for connector
    translate([0, 0, -3]) {
        cylinder(h=depth+5, d=speakon_diameter, center=false, $fn=100);
    }

    // Mounting holes with correct alignment
    // Left hole - top edge aligned with center hole's top edge
    translate([-speakon_mount_distance/2, (speakon_diameter/2 - speakon_mount_diameter/2), -3]) {
        cylinder(h=depth+5, d=speakon_mount_diameter, center=false, $fn=100);
    }
    // Right hole - bottom edge aligned with center hole's bottom edge
    translate([speakon_mount_distance/2, -(speakon_diameter/2 - speakon_mount_diameter/2), -3]) {
        cylinder(h=depth+5, d=speakon_mount_diameter, center=false, $fn=100);
    }
}

// Set the quality of the rounded corners
$fn = 100;