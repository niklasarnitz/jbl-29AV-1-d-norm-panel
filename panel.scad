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
outer_recess_width = 38;  // mm
outer_recess_height = 31; // mm
outer_recess_corner_radius = 1; // mm

// Reinforcement parameters
chamfer_profile_size = 2.5; // mm (height and horizontal width of the 45-degree chamfer profile)

// Central Platform base Z and thickness of the vertical pillar part
platform_base_z = -2; // mm (top Z of the bottom chamfer / bottom Z of the pillar)
platform_thickness = 2; // mm (thickness of the central pillar, from platform_base_z to z=0)

// Derived dimensions for the central pillar (and top of bottom chamfer)
raised_platform_width = outer_recess_width - 2*chamfer_profile_size;
raised_platform_height = outer_recess_height - 2*chamfer_profile_size;
raised_platform_corner_radius = max(0.01, outer_recess_corner_radius - chamfer_profile_size);

// Dimensions for the wider base of the bottom chamfer
bottom_chamfer_outer_width = raised_platform_width + 2*chamfer_profile_size;
bottom_chamfer_outer_height = raised_platform_height + 2*chamfer_profile_size;
bottom_chamfer_outer_corner_radius = max(0.01, raised_platform_corner_radius + chamfer_profile_size);

// Z-level for the very bottom of the part (base of the bottom chamfer)
very_bottom_z = -chamfer_profile_size; // Bottom of chamfer is at -chamfer_profile_size

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

// Module to create a chamfered cutting tool for the recess (top side)
module ChamferedRecessCutout(cut_width, cut_height, cut_radius, cut_chamfer_size, cut_panel_depth) {
    inner_dim_width = cut_width - 2*cut_chamfer_size;
    inner_dim_height = cut_height - 2*cut_chamfer_size;
    inner_dim_radius = max(0.01, cut_radius - cut_chamfer_size);
    union() {
        translate([0,0,cut_chamfer_size])
            linear_extrude(height = cut_panel_depth - cut_chamfer_size + 0.01)
                rounded_square(cut_width, cut_height, cut_radius);
        hull() {
            translate([0,0,0])
                linear_extrude(height=0.01)
                    rounded_square(inner_dim_width, inner_dim_height, inner_dim_radius);
            translate([0,0,cut_chamfer_size])
                linear_extrude(height=0.01)
                    rounded_square(cut_width, cut_height, cut_radius);
        }
    }
}

// Create the 3D panel
difference() { // Final difference for Speakon connector cutouts
    union() { // Union of the main panel and the central platform structure

        // Main Panel Body with Top Chamfered Recess and Corner Holes/Countersinks
        difference() {
            linear_extrude(height=depth) {
                difference() {
                    rounded_square(width, height, corner_radius);
                    translate([ width/2-hole_edge_distance,  height/2-hole_edge_distance, -0.01]) circle(d=hole_diameter);
                    translate([-width/2+hole_edge_distance,  height/2-hole_edge_distance, -0.01]) circle(d=hole_diameter);
                    translate([ width/2-hole_edge_distance, -height/2+hole_edge_distance, -0.01]) circle(d=hole_diameter);
                    translate([-width/2+hole_edge_distance, -height/2+hole_edge_distance, -0.01]) circle(d=hole_diameter);
                }
            }
            ChamferedRecessCutout(outer_recess_width, outer_recess_height, outer_recess_corner_radius, chamfer_profile_size, depth);
            translate([ width/2-hole_edge_distance,  height/2-hole_edge_distance, depth-countersink_depth])
                cylinder(h=countersink_depth+0.02, d=countersink_diameter);
            translate([-width/2+hole_edge_distance,  height/2-hole_edge_distance, depth-countersink_depth])
                cylinder(h=countersink_depth+0.02, d=countersink_diameter);
            translate([ width/2-hole_edge_distance, -height/2+hole_edge_distance, depth-countersink_depth])
                cylinder(h=countersink_depth+0.02, d=countersink_diameter);
            translate([-width/2+hole_edge_distance, -height/2+hole_edge_distance, depth-countersink_depth])
                cylinder(h=countersink_depth+0.02, d=countersink_diameter);
        }

        // Central Platform Structure (Pillar + Bottom Chamfer)
        union() {
            // Central Pillar (from platform_base_z to z=0)
            translate([0, 0, platform_base_z]) {
                linear_extrude(height=platform_thickness) {
                    rounded_square(raised_platform_width, raised_platform_height, raised_platform_corner_radius);
                }
            }

            // Bottom Chamfer
            // Slopes from raised_platform dimensions at z=platform_base_z
            // down to bottom_chamfer_outer dimensions at z=very_bottom_z
            translate([0,0, 0]) rotate([0, 180, 0]) { // Base of this hull operation is at z=0
                hull() {
                    linear_extrude(height=0.01)
                        rounded_square(bottom_chamfer_outer_width, bottom_chamfer_outer_height, bottom_chamfer_outer_corner_radius);

                    // Upper, narrower shape of the chamfer (at z=platform_base_z)
                    translate([0,0,chamfer_profile_size])
                        linear_extrude(height=0.01)
                            rounded_square(raised_platform_width, raised_platform_height, raised_platform_corner_radius);
                }
            }
        }
    }

    // Speakon connector cutouts - cut through the entire assembly
    // Total height from new very bottom of platform to top of panel: depth - very_bottom_z
    cutout_total_height = depth - very_bottom_z + 0.02; // Add epsilon for clean cut

    // Main center hole for connector
    translate([0, 0, very_bottom_z - 0.01]) { // Start cut slightly below the new very bottom
        cylinder(h = cutout_total_height, d=speakon_diameter, center=false);
    }

    // Mounting holes for Speakon
    translate([-speakon_mount_distance/2, (speakon_diameter/2 - speakon_mount_diameter/2), very_bottom_z - 0.01]) {
        cylinder(h = cutout_total_height, d=speakon_mount_diameter, center=false);
    }
    translate([speakon_mount_distance/2, -(speakon_diameter/2 - speakon_mount_diameter/2), very_bottom_z - 0.01]) {
        cylinder(h = cutout_total_height, d=speakon_mount_diameter, center=false);
    }
}