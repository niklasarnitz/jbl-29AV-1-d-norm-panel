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

// Outer dimensions of the recessed area (at the panel face or top of chamfer)
outer_recess_width = 38;  // mm (Previously rect_width)
outer_recess_height = 31; // mm (Previously rect_height)
outer_recess_corner_radius = 1; // mm (Previously rect_corner_radius)

// Reinforcement parameters
chamfer_profile_size = 2.5; // mm (height and horizontal width of the 45-degree chamfer profile)
                            // Increased from 1.5mm to make the chamfer more substantial

// Central Platform base Z and thickness
platform_base_z = -2; // mm (bottom Z of the central platform)
platform_thickness = 2; // mm (thickness of the central platform, from platform_base_z to z=0)

// Derived dimensions for the actual raised flat part of the platform
// This is narrower/smaller due to the chamfer extending inwards
raised_platform_width = outer_recess_width - 2*chamfer_profile_size;
raised_platform_height = outer_recess_height - 2*chamfer_profile_size;
// Ensure corner radius of the raised platform doesn't become negative
raised_platform_corner_radius = max(0.01, outer_recess_corner_radius - chamfer_profile_size);

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
// cut_width/height are the OUTER dimensions of the chamfer (at the top of the chamfer)
module ChamferedRecessCutout(cut_width, cut_height, cut_radius, cut_chamfer_size, cut_panel_depth) {
    // Inner dimensions at the base of the chamfer (at z=0 of the cut)
    inner_dim_width = cut_width - 2*cut_chamfer_size;
    inner_dim_height = cut_height - 2*cut_chamfer_size;
    inner_dim_radius = max(0.01, cut_radius - cut_chamfer_size);

    union() {
        // Upper straight part of the recess wall (above the chamfer)
        translate([0,0,cut_chamfer_size])
            linear_extrude(height = cut_panel_depth - cut_chamfer_size + 0.01) // +0.01 to ensure cut through
                rounded_square(cut_width, cut_height, cut_radius);

        // Chamfered lower part of the recess wall
        hull() {
            translate([0,0,0]) // Base of chamfer (narrower)
                linear_extrude(height=0.01)
                    rounded_square(inner_dim_width, inner_dim_height, inner_dim_radius);
            translate([0,0,cut_chamfer_size]) // Top of chamfer (wider)
                linear_extrude(height=0.01)
                    rounded_square(cut_width, cut_height, cut_radius);
        }
    }
}

// Create the 3D panel
difference() { // Final difference for Speakon connector cutouts
    union() { // Union of the main panel (with chamfered recess) and the central platform

        // Main Panel Body with Chamfered Recess and Corner Holes/Countersinks
        difference() {
            // Base panel slab (from z=0 to z=depth)
            linear_extrude(height=depth) {
                difference() {
                    // Panel outer shape
                    rounded_square(width, height, corner_radius);

                    // Corner holes for panel mounting (cut before chamfering recess)
                    translate([ width/2-hole_edge_distance,  height/2-hole_edge_distance, -0.01]) circle(d=hole_diameter);
                    translate([-width/2+hole_edge_distance,  height/2-hole_edge_distance, -0.01]) circle(d=hole_diameter);
                    translate([ width/2-hole_edge_distance, -height/2+hole_edge_distance, -0.01]) circle(d=hole_diameter);
                    translate([-width/2+hole_edge_distance, -height/2+hole_edge_distance, -0.01]) circle(d=hole_diameter);
                }
            }

            // Chamfered recess cut from the main panel slab
            // This cut is made from z=0 (panel's local Z) up to z=depth
            ChamferedRecessCutout(outer_recess_width, outer_recess_height, outer_recess_corner_radius, chamfer_profile_size, depth);

            // Countersinks for the corner holes (applied from the top surface z=depth)
            translate([ width/2-hole_edge_distance,  height/2-hole_edge_distance, depth-countersink_depth])
                cylinder(h=countersink_depth+0.02, d=countersink_diameter);
            translate([-width/2+hole_edge_distance,  height/2-hole_edge_distance, depth-countersink_depth])
                cylinder(h=countersink_depth+0.02, d=countersink_diameter);
            translate([ width/2-hole_edge_distance, -height/2+hole_edge_distance, depth-countersink_depth])
                cylinder(h=countersink_depth+0.02, d=countersink_diameter);
            translate([-width/2+hole_edge_distance, -height/2+hole_edge_distance, depth-countersink_depth])
                cylinder(h=countersink_depth+0.02, d=countersink_diameter);
        }

        // Central Raised Platform (the part that was previously breaking)
        // This platform extends from platform_base_z to z=0.
        // Its dimensions match the *inner* start of the chamfer.
        translate([0, 0, platform_base_z]) {
            linear_extrude(height=platform_thickness) {
                rounded_square(raised_platform_width, raised_platform_height, raised_platform_corner_radius);
            }
        }
    }

    // Speakon connector cutouts - cut through the entire assembly
    // Total height from bottom of platform to top of panel: depth - platform_base_z
    cutout_height = depth - platform_base_z + 0.02; // Add epsilon for clean cut

    // Main center hole for connector
    translate([0, 0, platform_base_z - 0.01]) { // Start cut slightly below platform base
        cylinder(h = cutout_height, d=speakon_diameter, center=false);
    }

    // Mounting holes for Speakon
    translate([-speakon_mount_distance/2, (speakon_diameter/2 - speakon_mount_diameter/2), platform_base_z - 0.01]) {
        cylinder(h = cutout_height, d=speakon_mount_diameter, center=false);
    }
    translate([speakon_mount_distance/2, -(speakon_diameter/2 - speakon_mount_diameter/2), platform_base_z - 0.01]) {
        cylinder(h = cutout_height, d=speakon_mount_diameter, center=false);
    }
}