// Panel dimensions
width = 57;    // mm
height = 57;   // mm
depth = 3;     // mm // This is the thickness of the outer panel frame (from z=0 to z=3)
corner_radius = 6; // mm

// Hole parameters
hole_diameter = 4;     // mm
hole_edge_distance = 6.5;   // mm from edge of panel to center of hole
countersink_diameter = 6;   // mm
countersink_depth = 1.5;      // mm

// Central platform and recess parameters
rect_width = 38;  // mm
rect_height = 31; // mm
rect_corner_radius = 1; // mm

// Reinforcement parameters
recess_chamfer_size = 1.5; // mm (height and width of the 45-degree chamfer)

// Central Platform dimensions (derived from original logic: z=-2 to z=0)
platform_base_z = -2; // mm (bottom Z of the central platform)
platform_thickness = 2; // mm (thickness of the central platform)

// Neutrik D-Norm Speakon connector parameters
speakon_diameter = 24;      // mm (main connector hole)
speakon_mount_diameter = 3.2;  // mm (mounting holes)
speakon_mount_distance = 24;   // mm (distance between mounting holes centers)

// Set the quality of the rounded corners globally
$fn = 100;

// Create the rounded square 2D shape
module rounded_square(size_x, size_y, radius) {
    x_adj = size_x/2 - radius;
    y_adj = size_y/2 - radius;

    hull() {
        translate([ x_adj,  y_adj, 0]) circle(r=radius);
        translate([-x_adj,  y_adj, 0]) circle(r=radius);
        translate([ x_adj, -y_adj, 0]) circle(r=radius);
        translate([-x_adj, -y_adj, 0]) circle(r=radius);
    }
}

// Module to create a chamfered cutting tool for the recess
module ChamferedRecessCutout(cut_width, cut_height, cut_radius, cut_chamfer_size, cut_panel_depth) {
    inner_cut_width = cut_width - 2*cut_chamfer_size;
    inner_cut_height = cut_height - 2*cut_chamfer_size;
    inner_cut_radius = max(0.01, cut_radius - cut_chamfer_size); // Ensure radius doesn't become zero or negative

    union() {
        // Upper straight part of the hole
        translate([0,0,cut_chamfer_size])
            linear_extrude(height = cut_panel_depth - cut_chamfer_size + 0.01) // +0.01 to ensure cut through
                rounded_square(cut_width, cut_height, cut_radius); // Call module directly

        // Chamfered lower part of the hole
        hull() {
            translate([0,0,0])
                linear_extrude(height=0.01) // Thin slice for hull
                    rounded_square(inner_cut_width, inner_cut_height, inner_cut_radius); // Call module directly
            translate([0,0,cut_chamfer_size])
                linear_extrude(height=0.01) // Thin slice for hull
                    rounded_square(cut_width, cut_height, cut_radius); // Call module directly
        }
    }
}

// Create the 3D panel
difference() { // Final difference for Speakon connector cutouts
    union() { // Union of the main panel (with chamfered recess) and the central platform

        // Main Panel Body with Chamfered Recess and Corner Holes/Countersinks
        difference() {
            // Base panel slab
            linear_extrude(height=depth) {
                difference() {
                    // Panel outer shape
                    rounded_square(width, height, corner_radius);

                    // Corner holes for panel mounting
                    translate([ width/2-hole_edge_distance,  height/2-hole_edge_distance, -0.01]) circle(d=hole_diameter);
                    translate([-width/2+hole_edge_distance,  height/2-hole_edge_distance, -0.01]) circle(d=hole_diameter);
                    translate([ width/2-hole_edge_distance, -height/2+hole_edge_distance, -0.01]) circle(d=hole_diameter);
                    translate([-width/2+hole_edge_distance, -height/2+hole_edge_distance, -0.01]) circle(d=hole_diameter);
                }
            }

            // Chamfered recess cut from the main panel slab
            // This cut is made from z=0 to z=depth of the panel
            ChamferedRecessCutout(rect_width, rect_height, rect_corner_radius, recess_chamfer_size, depth);

            // Countersinks for the corner holes (applied from the top surface z=depth)
            translate([ width/2-hole_edge_distance,  height/2-hole_edge_distance, depth-countersink_depth])
                cylinder(h=countersink_depth+0.02, d=countersink_diameter); // +0.02 to ensure cut through
            translate([-width/2+hole_edge_distance,  height/2-hole_edge_distance, depth-countersink_depth])
                cylinder(h=countersink_depth+0.02, d=countersink_diameter);
            translate([ width/2-hole_edge_distance, -height/2+hole_edge_distance, depth-countersink_depth])
                cylinder(h=countersink_depth+0.02, d=countersink_diameter);
            translate([-width/2+hole_edge_distance, -height/2+hole_edge_distance, depth-countersink_depth])
                cylinder(h=countersink_depth+0.02, d=countersink_diameter);
        }

        // Central Platform (the part that was previously breaking)
        // This platform extends from platform_base_z to z=0
        translate([0, 0, platform_base_z]) {
            linear_extrude(height=platform_thickness) {
                rounded_square(rect_width, rect_height, rect_corner_radius);
            }
        }
    }

    // Speakon connector cutouts - cut through the entire assembly
    // Main center hole for connector
    translate([0, 0, platform_base_z - 0.01]) { // Start cut slightly below platform base
        cylinder(h = depth + platform_thickness + platform_base_z + 0.02, d=speakon_diameter, center=false); // Adjusted height
    }

    // Mounting holes for Speakon
    // Adjusted Z to cut through entire relevant thickness
    translate([-speakon_mount_distance/2, (speakon_diameter/2 - speakon_mount_diameter/2), platform_base_z - 0.01]) {
        cylinder(h = depth + platform_thickness + platform_base_z + 0.02, d=speakon_mount_diameter, center=false); // Adjusted height
    }
    translate([speakon_mount_distance/2, -(speakon_diameter/2 - speakon_mount_diameter/2), platform_base_z - 0.01]) {
        cylinder(h = depth + platform_thickness + platform_base_z + 0.02, d=speakon_mount_diameter, center=false); // Adjusted height
    }
}