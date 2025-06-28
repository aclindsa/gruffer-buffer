include <external/threads/threads.scad>
//$fn=180;
$fn=60;

case_lid_height = 3.5;
case_lid_perimeter_height = 2.5;
case_wall_thickness = 2;
case_total_outer_width = 12; // includes case and lid, nested
case_outer_height = 225;
case_outer_width = 180;
case_outer_depth = case_total_outer_width - (case_lid_height - case_lid_perimeter_height);
case_outer_base_width = 100;
case_outer_base_height = 12;

bearing_inner_diameter = 8.07;
bearing_inner_support_diameter = bearing_inner_diameter + 3;
bearing_outer_diameter = 22.2;
bearing_width = 7;

locking_post_height=4;
locking_post_radius=2;
locking_post_peg_radius=1;
locking_post_tolerance=0.2;

pulley_outer_diameter = 75;
pulley_case_inset = 0.25;
pulley_case_inset_diameter_diff = 2;
pulley_min_gap = 5;
case_pulley_circular_support_diameter = 30;

module half_circle(r=1, half="right") {
    intersection() {
        circle(r=r);
        if (half == "right") {
            translate([0, -r, 0]) square([2*r, 2*r]);
        } else if (half == "left") {
            translate([-2*r, -r, 0]) square([2*r, 2*r]);
        } else if (half == "top") {
            translate([-r, 0, 0]) square([2*r, 2*r]);
        } else {
            assert(half == "bottom", "half must be 'right', 'left', 'top', or 'bottom'");
            translate([-r, -2*r, 0]) square([2*r, 2*r]);
        }
    }
}

module hexagon(diameter, height) {
    rotate([0, 0, 30]) cylinder(d = diameter, h = height, $fn = 6);
}

module hexagon_pattern(box, diameter, wall_thickness) {
    hexagon_width_x = diameter * cos(30);
    hexagon_width_y = diameter;
    hexagon_offset_x = hexagon_width_x + wall_thickness;
    hexagon_side_length = diameter * sin(30);
    hexagon_offset_y = hexagon_side_length/2 + diameter/2 + wall_thickness / cos(30) - wall_thickness/2 * tan(30);

    num_columns = ceil(box[0] / hexagon_offset_x) + 1;
    num_rows = ceil(box[1] / hexagon_offset_y) + 1;
    half_x = ceil(num_columns * hexagon_offset_x / 2) - wall_thickness/2;
    half_y = ceil(num_rows * hexagon_offset_y / 2);

    for(x = [-half_x: hexagon_offset_x: half_x]) {
        for(y = [-half_y + (wall_thickness / cos(30) - wall_thickness/2 * tan(30)): 2 * hexagon_offset_y: half_y]) {
            translate([x, y, -box[2]/2]) hexagon(diameter, box[2]);
            translate([x + hexagon_offset_x/2, y + hexagon_offset_y, -box[2]/2]) hexagon(diameter, box[2]);
        }
    }
}

case_top_corner_vertical_offset = 15;
case_top_corner_horizontal_offset = 40;
case_corner_radius = pulley_outer_diameter/2;
ptfe_support_horizontal_offset = 45;

module case_shape_2d(inset, interior) {
    corner_radius = case_corner_radius - inset;
    half_width = case_outer_width/2 - inset;
    half_height = case_outer_height/2 - inset;
    union() {
        hull() {
            translate([-half_width + case_top_corner_horizontal_offset + corner_radius, half_height - corner_radius, 0]) circle(r=corner_radius);
            translate([-half_width + corner_radius, half_height - case_top_corner_vertical_offset - corner_radius, 0]) circle(r=corner_radius);
            translate([-half_width + corner_radius, -half_height + corner_radius, 0]) circle(r=corner_radius);
            translate([half_width - corner_radius, -half_height + corner_radius, 0]) circle(r=corner_radius);
            translate([half_width - 0.01, half_height - 0.01, 0]) square([0.01, 0.01]);
        }

        if (interior != true) {
            // extra 'square' piece to hold PTFE tube to spool
            translate([-half_width + ptfe_support_horizontal_offset, half_height - ptfe_support_horizontal_offset, 0]) square([ptfe_support_horizontal_offset, ptfe_support_horizontal_offset]);
        }
    }
}

module case_shape(interior=true, inset=0, height) {
    linear_extrude(h=height)
        case_shape_2d(interior=interior, inset=inset);
}

hex_grid_diameter = 24;
module case_bottom_hexagons() {
    intersection() {
        translate([0, 0, case_wall_thickness/2]) hexagon_pattern([case_outer_width, case_outer_height, case_wall_thickness+0.02], hex_grid_diameter, 2);
        translate([0, 0, -0.01])
        case_shape(inset=case_wall_thickness*2, height=case_wall_thickness+0.02);
    }
}

module lid_hexagons() {
    translate([0, 0, case_outer_depth - case_lid_perimeter_height])
    intersection() {
        translate([0, 0, case_lid_height/2]) hexagon_pattern([case_outer_width, case_outer_height, case_lid_height+0.02], hex_grid_diameter, 2);
        translate([0, 0, -0.01])
        difference() {
            case_shape(inset=case_wall_thickness*2, height=case_lid_height+0.02);
        }
    }
}

module case_interior() {
    difference() {
        union() {
            // bulk of the inside of the case
            translate([0, 0, case_wall_thickness])
                case_shape(inset=case_wall_thickness, height=case_outer_depth);
            // take away some hexagons from the bottom
            case_bottom_hexagons();
        }
    }
}

module lid_shape(extra_perimeter_inset=0) {
    translate([0, 0, case_outer_depth - case_lid_perimeter_height])
    union() {
        translate([0, 0, case_lid_perimeter_height])
            case_shape(height=case_lid_height - case_lid_perimeter_height);
        difference() {
            translate([0, 0, 0.01]) case_shape(inset=case_wall_thickness, height=case_lid_perimeter_height+0.01);
            case_shape(inset=case_wall_thickness*2+extra_perimeter_inset, height=case_lid_height - case_wall_thickness);
        }
    }
}

ptfe_hole_large_radius = 4.3/2;
ptfe_hole_small_radius = 2.5/2;
ptfe_hole_angle = 9;
module ptfe_hole() {
    length = 60;
    rotate([0, -ptfe_hole_angle, 0])
    union() {
        cylinder(r=ptfe_hole_large_radius, h=length/2);
        translate([0, 0, -length/2]) cylinder(r=ptfe_hole_small_radius, h=length);
    }
}
module ptfe_holes() {
    bottom_corner_offset = (case_outer_width - case_outer_base_width)/2 + case_outer_base_height;
    y_offset = max(ptfe_hole_large_radius, pulley_min_gap/2);
    x_offset = -22;//y_offset - 1;
    z_offset = -2;

    // add holes for PTFE tubes
    translate([-case_outer_width/2 + ptfe_support_horizontal_offset - x_offset, case_outer_height/2 - case_wall_thickness - y_offset, case_total_outer_width/2 + z_offset]) rotate([0, -90, 0]) ptfe_hole();
}

container_thickness = 2;
case_hanger_tolerance = 0.1; // amount the hanger is inset away frorm case (case dimensions stay same)
case_hanger_cutout_skinny_width = case_total_outer_width - case_lid_height * 2;
case_hanger_cutout_wide_width = case_total_outer_width - case_wall_thickness * 2;
case_hanger_cutout_skinny_height = 20;
case_hanger_cutout_transition_height = 5;
case_hanger_cutout_wide_height = case_corner_radius;
case_hanger_cutout_total_height = case_hanger_cutout_skinny_height + case_hanger_cutout_transition_height + case_hanger_cutout_wide_height;
case_hanger_inner_width = case_hanger_cutout_wide_width - 2*case_hanger_tolerance;
case_hanger_body_angle = 5; // empirically determined to be ~5 degrees (tried measuring angle based on distances and it didn't work out because the sides of the box are curved slightly)
case_hanger_threads_diameter = 6;
case_hanger_threads_depth = 6;
case_hanger_threads_vertical_offset = 10;
hanger_guide_rail_length = case_hanger_cutout_wide_height;
hanger_guide_rail_diameter = case_wall_thickness - 2*case_hanger_tolerance;
case_hanger_width = case_total_outer_width + 2*hanger_guide_rail_diameter + 2*case_hanger_tolerance;
case_hanger_nut_depth = 8;
pc_connector_threads_diameter = 6;
pc_connector_threads_depth = 4;

module case_hanger_nut() {
//    translate([case_outer_width/2 + case_hanger_body_depth + container_thickness,
//        -case_outer_height/2 + case_hanger_top_height - case_hanger_height,
//        case_wall_thickness + case_hanger_tolerance + case_hanger_width/2])
//    rotate([0, -90, 0])
//    translate([0, 0, -case_hanger_nut_depth])
    difference() {
        union() {
            translate([0, 0, case_hanger_nut_depth-0.01])
            intersection() {
                    thread_depth = case_hanger_threads_depth + container_thickness*7/8;
                    taper_depth = (case_hanger_threads_diameter-2.5)/2;
                    ScrewThread(case_hanger_threads_diameter, thread_depth + taper_depth + 0.01,
                      tip_height=ThreadPitch(case_hanger_threads_diameter), tip_min_fract=0.75);
                    difference() {
                        hull() {
                            translate([0, 0, thread_depth + taper_depth]) cylinder(d=2.5, h=0.01);
                            cylinder(d=case_hanger_threads_diameter, h=thread_depth);
                        }
                        translate([0, 0, thread_depth])
                        hull() {
                            cylinder(d=2.5, h=0.01);
                            translate([0, 0, taper_depth]) cylinder(d=case_hanger_threads_diameter, h=thread_depth);
                        }
                    }
            }
            ScrewHole(outer_diam=pc_connector_threads_diameter, height=pc_connector_threads_depth)
                cylinder(d=15, h=case_hanger_nut_depth, $fn=6);
        }
        translate([0, 0, -0.01]) cylinder(d=2.5, h=50);
        translate([0,  0, pc_connector_threads_depth-0.01]) hull() {
            translate([0, 0, (pc_connector_threads_diameter-2.5)/2]) cylinder(d=2.5, h=0.01);
            cylinder(d=pc_connector_threads_diameter, h=0.01);
        }
    }
}

module case_lid_hanger_cutout(case=true) {
    // if this is the case, make the cutout high enough so that it blows all
    // the way through the top
    height_addition = case ? case_total_outer_width : 0;

    translate([case_outer_width/2 - case_wall_thickness*2 - 0.01,
        case_outer_height/2 - case_wall_thickness - case_hanger_cutout_total_height,
        case_wall_thickness])
    union() {
        translate([0, case_hanger_cutout_transition_height+case_hanger_cutout_wide_height, (case_hanger_cutout_wide_width-case_hanger_cutout_skinny_width)/2])
            cube([case_wall_thickness * 3, case_hanger_cutout_skinny_height, case_hanger_cutout_skinny_width + height_addition]);
        hull() {
            translate([0, case_hanger_cutout_transition_height+case_hanger_cutout_wide_height, (case_hanger_cutout_wide_width-case_hanger_cutout_skinny_width)/2])
                cube([case_wall_thickness * 3, 0.01, case_hanger_cutout_skinny_width + height_addition]);
        translate([0, case_hanger_cutout_wide_height-0.01, 0])
            cube([case_wall_thickness * 3, 0.01, case_hanger_cutout_wide_width + height_addition]);
        }
        cube([case_wall_thickness * 3, case_hanger_cutout_wide_height, case_hanger_cutout_wide_width + height_addition]);
    }
}

module case_hanger_addition() {
    translate([case_outer_width/2 - case_wall_thickness*2,
        case_outer_height/2 - case_wall_thickness - (case_hanger_cutout_skinny_height + case_hanger_cutout_transition_height) + 0.01,
        case_wall_thickness])
    cube([case_wall_thickness +0.01, case_hanger_cutout_skinny_height + case_hanger_cutout_transition_height, case_hanger_cutout_wide_width / 2]);
}

module case_hanger_inner_shape_cutout() {
    cut_depth = (case_hanger_cutout_wide_width-case_hanger_cutout_skinny_width)/2 + case_hanger_tolerance;
    translate([case_corner_radius - 2*case_wall_thickness + case_hanger_tolerance, case_corner_radius -(case_hanger_cutout_skinny_height + case_hanger_cutout_transition_height) + 0.01, case_hanger_inner_width+0.01])
    hull() {
        translate([0, case_hanger_cutout_transition_height, -cut_depth])
            cube([2*case_wall_thickness + 2*case_hanger_tolerance, case_hanger_cutout_skinny_height, cut_depth]);
        cube([2*case_wall_thickness + 2*case_hanger_tolerance, 0.01, 0.01]);
        translate([-cut_depth, 0, 0])
            cube([0.01, case_hanger_cutout_skinny_height + case_hanger_cutout_transition_height, 0.01]);
    }
}

module case_hanger_inner_shape() {
    translate([-case_corner_radius-0.01, -case_corner_radius-case_wall_thickness-0.01, -case_hanger_inner_width/2])
    difference() {
        translate([0.4*case_corner_radius, 0, 0])
            cube([0.6*case_corner_radius, case_corner_radius, case_hanger_inner_width]);
        case_hanger_inner_shape_cutout();
        translate([0, 0, case_hanger_inner_width])
            mirror([0, 0, 1])
            case_hanger_inner_shape_cutout();
        translate([0, 0, -0.01])
        cylinder(r=case_corner_radius+0.01, h=case_hanger_inner_width+0.02);
    }
}

module case_hanger_guide_rail() {
    rotate([0, -90, 0])
    translate([0, -hanger_guide_rail_length, 0])
    union() {
        translate([0, hanger_guide_rail_diameter/2, 0]) cylinder(d=hanger_guide_rail_diameter, h=hanger_guide_rail_diameter*3/2, $fn=$fn/4);
        translate([0, hanger_guide_rail_diameter/2, hanger_guide_rail_diameter*3/2]) sphere(d=hanger_guide_rail_diameter, $fn=$fn/4);
        translate([0, hanger_guide_rail_length - hanger_guide_rail_diameter/2, 0]) cylinder(d=hanger_guide_rail_diameter, h=hanger_guide_rail_diameter*3/2, $fn=$fn/4);
        translate([0, hanger_guide_rail_length - hanger_guide_rail_diameter/2, hanger_guide_rail_diameter*3/2]) sphere(d=hanger_guide_rail_diameter, $fn=$fn/4);
        translate([0, hanger_guide_rail_diameter/2, hanger_guide_rail_diameter*3/2]) rotate([-90, 0, 0]) cylinder(d=hanger_guide_rail_diameter, h=hanger_guide_rail_length - hanger_guide_rail_diameter, $fn=$fn/4);
        translate([-hanger_guide_rail_diameter/2, hanger_guide_rail_diameter/2, 0]) cube([hanger_guide_rail_diameter, hanger_guide_rail_length - hanger_guide_rail_diameter, hanger_guide_rail_diameter*3/2]);
    }
}

module case_hanger_block() {
    height = case_hanger_cutout_total_height + 10;
    translate([height/2, -height/2, 0])
        cube([height, height, case_hanger_width], center=true);
}

module case_hanger_holes() {
    height = case_hanger_cutout_total_height + 10;
    translate([0, -case_hanger_threads_vertical_offset, 0])
    difference() {
        ScrewHole(outer_diam=case_hanger_threads_diameter, height=case_hanger_threads_depth+0.01, rotation=[0, 90, 0], position=[-case_hanger_threads_depth, 0, 0])
            translate([-height/2, -height/2, 0])
            cube([height, 2*height, case_hanger_width], center=true);

        translate([-50, 0, 0]) rotate([0, 90, 0]) cylinder(d=2.5, h=100);
        translate([0.01, 0, 0]) rotate([0, 90, 0]) hull() {
            translate([0, 0, -case_hanger_width/2]) cylinder(d=2.5, h=0.01);
            cylinder(d=case_hanger_threads_diameter, h=0.01);
        }
    }
}

module case_hanger_rotation_placement(reverse=false) {
    if (reverse) {
        translate([0, -case_outer_height, 0])
        rotate([0, 0, 5])
        translate([8, case_outer_height, 0])
        children();
    } else {
        translate([-8, -case_outer_height, 0])
        rotate([0, 0, -5])
        translate([0, case_outer_height, 0])
        children();
    }
}

module case_hanger() {
    case_hanger_rotation_placement(reverse=true)
    intersection() {
        union() {
            case_hanger_inner_shape();
            translate([0, 0, -case_hanger_width/2+hanger_guide_rail_diameter/2])
                case_hanger_guide_rail();
            translate([0, 0, case_hanger_width/2-hanger_guide_rail_diameter/2])
                case_hanger_guide_rail();
            case_hanger_block();
        }
        case_hanger_rotation_placement()
        case_hanger_holes();
    }
}

module lid(mirrored=false) {
    mirror_args = mirrored ? [1, 0, 0] : [0, 0, 0];
    mirror(mirror_args)
    union() {
        difference() {
            lid_shape();
            lid_hexagons();
            position_pulley() pulley_tray();
            case_lid_hanger_cutout(case=false);
        }
        pills();
        lid_pulley_spindle(mirrored=mirrored);
    }
}

module case(mirrored=false) {
    mirror_args = mirrored ? [1, 0, 0] : [0, 0, 0];
    mirror(mirror_args)
    union() {
        difference() {
            case_shape(interior=false, height=case_outer_depth);
            difference() {
                case_interior();
                case_hanger_addition();
            }
            lid_shape(extra_perimeter_inset=0.1);
            ptfe_holes();
            position_pulley() pulley_tray();
            pills();
            case_lid_hanger_cutout(case=true);
        }
        case_pulley_spindle(mirrored=mirrored);
    }
}

module locking_peg_2d(r, post_length) {
    half_circle(r=r, half="top");
    translate([0, -post_length/2+0.01, 0]) square([2*r, post_length+0.02], center=true);
}
module locking_peg(r=2.5, post_length=2.5) {
    rotate_extrude(start=0) intersection() {
        locking_peg_2d(r=r, post_length=post_length);
        translate([0, -2*r]) square([4*r, 4*r]);
    }
}
module locking_post(post_radius=locking_post_radius, peg_radius=locking_post_peg_radius, post_height=locking_post_height) {
    rotate([0, 0, 90]) translate([0, 0, bearing_width-locking_post_height + 0.01])
    union() {
        cylinder(r=post_radius, h=post_height);
        translate([-post_radius, 0, peg_radius]) rotate([0, -90, 0]) locking_peg(r=peg_radius, post_length=post_radius-peg_radius);
        translate([post_radius, 0, peg_radius]) rotate([0, 90, 0]) locking_peg(r=peg_radius, post_length=post_radius-peg_radius);
    }
}

module locking_post_receptacle(post_hole_radius=locking_post_radius+locking_post_tolerance, post_hole_height=locking_post_height, peg_radius=locking_post_peg_radius+locking_post_tolerance, post_height=bearing_width) {
    difference() {
        cylinder(r=bearing_inner_diameter/2, h=post_height);
        union() {
            translate([0, 0, post_height - post_hole_height + 0.01]) union() {
                cylinder(r=post_hole_radius, h=post_hole_height);

                // vertical slots going down into the hole
                translate([-post_hole_radius, 0, peg_radius]) rotate([0, 0, 90]) linear_extrude(height=post_hole_height-peg_radius) locking_peg_2d(r=peg_radius, post_length=post_hole_radius-peg_radius);
                translate([post_hole_radius, 0, peg_radius]) rotate([0, 0, -90]) linear_extrude(height=post_hole_height-peg_radius) locking_peg_2d(r=peg_radius, post_length=post_hole_radius-peg_radius);

                // pegs at the ends of the slots
                translate([0, post_hole_radius, peg_radius]) rotate([0, 90, 90]) locking_peg(r=peg_radius, post_length=post_hole_radius-peg_radius);
                translate([0, -post_hole_radius, peg_radius]) rotate([0, 90, -90]) locking_peg(r=peg_radius, post_length=post_hole_radius-peg_radius);
                translate([-post_hole_radius, 0, peg_radius]) rotate([0, 90, 180]) locking_peg(r=peg_radius, post_length=post_hole_radius-peg_radius);
                translate([post_hole_radius, 0, peg_radius]) rotate([0, 90, 0]) locking_peg(r=peg_radius, post_length=post_hole_radius-peg_radius);

                // rotational slots for pegs to turn in
                rotate_extrude(angle=90, start=90) translate([post_hole_radius, peg_radius, 0]) rotate([0, 0, -90]) locking_peg_2d(peg_radius, post_length=post_hole_radius-peg_radius);
                rotate_extrude(angle=90, start=270) translate([post_hole_radius, peg_radius, 0]) rotate([0, 0, -90]) locking_peg_2d(peg_radius, post_length=post_hole_radius-peg_radius);
            }
        }
    }
}

module pulley_cutout(start_diameter, stop_diameter, width, spoke_width, bevel=2, spokes=6) {
    difference() {
        difference() { // Create a "donut"
            union() { // outer donut (bevels in)
                scale = 1.0 - bevel/(stop_diameter/2);
                translate([0, 0, width/2]) rotate([180, 0, 0]) linear_extrude(width/2, scale=scale) circle(stop_diameter/2);
                translate([0, 0, -width/2]) linear_extrude(width/2+0.01, scale=scale) circle(stop_diameter/2);
            }
            union() { // inner donut (bevels out)
                scale = 1.0 + bevel/(start_diameter/2);
                translate([0, 0, -width/2-0.01]) linear_extrude(width/2+0.02, scale=scale) circle(start_diameter/2);
                translate([0, 0, width/2+0.01]) rotate([180, 0, 0]) linear_extrude(width/2+0.02, scale=scale) circle(start_diameter/2);
            }
        }
        // Create spokes to subtract from donut
        degrees_per_spoke = 360 / spokes;
        for(rotate_degrees = [0: degrees_per_spoke: 359.999]) {
            scale = 1.0 + bevel/spoke_width*2;
            rotate([0, 0, rotate_degrees]) union() {
                translate([0, 0, width/2+0.01]) rotate([180, 0, 0]) linear_extrude(width/2+0.01, scale=[1, scale]) translate([0, -spoke_width/2, 0]) square([stop_diameter*2, spoke_width]);
                translate([0, 0, -width/2-0.01]) linear_extrude(width/2+0.02, scale=[1, scale]) translate([0, -spoke_width/2, 0]) square([stop_diameter*2, spoke_width]);
            }
        }
    }
}

module pulley(inner_diameter=bearing_outer_diameter, outer_diameter=pulley_outer_diameter, width=pulley_width, channel_depth=1) {
    difference() {
        translate([0, 0, -width/2]) // center the main part of the pulley on the z-axis
        rotate_extrude(angle=360) {
            difference() {
                // "main" part of the pulley - a rectangle which gets spun
                // around the z-axis to make a circle
                translate([inner_diameter/2, 0, 0]) square([outer_diameter/2 - inner_diameter/2, width]);
                // cut a channel around the outside of the pulley
                if (channel_depth >= width/2) {
                    // If the channel is deeper than the pulley is wide, just
                    // make a circle and scale it to the right depth
                    translate([outer_diameter/2, width/2, 0]) scale([2 * channel_depth / width, 1, 1]) circle(r=width/2);
                } else {
                    // If the channel is shallower than the pulley is wide
                    // create a circle of the right radius to cut a channel that deep
                    channel_radius = width*width/(8*channel_depth) + channel_depth/2;
                    translate([outer_diameter/2 + channel_radius - channel_depth, width/2, 0]) circle(r=channel_radius);
                }
            }
        }
        // remove a pattern in the middle of the pulley to create spokes
        pulley_cutout(inner_diameter + 3, outer_diameter - 3, width + 0.01, spoke_width=1.5, spokes=7);
    }
}

pulley_width = case_total_outer_width - 2*case_wall_thickness;
module position_pulley() {
    translate([case_outer_width/2 - (case_outer_width-case_top_corner_horizontal_offset)/2,
        case_outer_height/2 - case_wall_thickness - pulley_min_gap - pulley_outer_diameter/2,
        case_wall_thickness + pulley_width/2])
    children();
}

module pulley_tray() {
    translate([0, 0, -pulley_width/2 - pulley_case_inset])
    cylinder(d=pulley_outer_diameter-pulley_case_inset_diameter_diff, h=pulley_width + 2*pulley_case_inset);
}

module case_pulley_spindle(mirrored=false) {
    mirror_args = mirrored ? [1, 0, 0] : [0, 0, 0];
    bearing_z_offset = (pulley_width - bearing_width)/2;
    position_pulley()
    mirror(mirror_args)
    translate([0, 0, -case_wall_thickness - pulley_width/2])
    union() {
        cylinder(d=case_pulley_circular_support_diameter, h=case_wall_thickness - pulley_case_inset);
        cylinder(d=bearing_inner_support_diameter, h=case_wall_thickness + bearing_z_offset);
        translate([0, 0, case_wall_thickness + bearing_z_offset-0.01]) locking_post_receptacle();
    }
}

module lid_pulley_spindle(mirrored=false) {
    mirror_args = mirrored ? [1, 0, 0] : [0, 0, 0];
    bearing_z_offset = (pulley_width - bearing_width)/2;
    position_pulley()
    mirror(mirror_args)
    translate([0, 0, -case_wall_thickness - pulley_width/2])
    union() {
        translate([0, 0, case_wall_thickness + pulley_case_inset + pulley_width]) cylinder(d=case_pulley_circular_support_diameter, h=case_wall_thickness - pulley_case_inset);
        translate([0, 0, case_wall_thickness + bearing_z_offset + bearing_width]) cylinder(d=bearing_inner_support_diameter, h=case_wall_thickness + bearing_z_offset);
        translate([0, 0, case_wall_thickness + bearing_z_offset-0.01]) locking_post();
    }
}

pill_radius = 0.75;
pill_length = 5;
module pill() {
    hull() {
        translate([-pill_length/2, 0, 0]) sphere(r=pill_radius);
        translate([pill_length/2, 0, 0]) sphere(r=pill_radius);
    }
}

module pills() {
    pill_height = case_outer_depth - case_lid_perimeter_height + pill_radius;

    // pills on top
    top_width_remaining = case_outer_width - case_corner_radius - case_top_corner_horizontal_offset;
    translate([case_outer_width/2 - top_width_remaining/4, case_outer_height/2 - case_wall_thickness, pill_height]) pill();
    translate([case_outer_width/2 - top_width_remaining*3/4, case_outer_height/2 - case_wall_thickness, pill_height]) pill();

    // pills on bottom
    bottom_width_remaining = case_outer_width - 2*case_corner_radius;
    translate([-case_outer_width/2 + case_corner_radius + bottom_width_remaining/10, -case_outer_height/2 + case_wall_thickness, pill_height]) pill();
    translate([-case_outer_width/2 + case_corner_radius + bottom_width_remaining/2, -case_outer_height/2 + case_wall_thickness, pill_height]) pill();
    translate([-case_outer_width/2 + case_corner_radius + bottom_width_remaining*9/10, -case_outer_height/2 + case_wall_thickness, pill_height]) pill();

    // pills on right side
    right_height_remaining = case_outer_height - case_corner_radius - case_hanger_cutout_total_height;
    translate([case_outer_width/2 - case_wall_thickness, -case_outer_height/2 + case_corner_radius + right_height_remaining/10, pill_height]) rotate([0, 0, 90]) pill();
    translate([case_outer_width/2 - case_wall_thickness, -case_outer_height/2 + case_corner_radius + right_height_remaining/2, pill_height]) rotate([0, 0, 90]) pill();
    translate([case_outer_width/2 - case_wall_thickness, -case_outer_height/2 + case_corner_radius + right_height_remaining*9/10, pill_height]) rotate([0, 0, 90]) pill();

    // pills on left side
    left_height_remaining = case_outer_height - case_corner_radius*2 - case_top_corner_vertical_offset;
    translate([-case_outer_width/2 + case_wall_thickness, -case_outer_height/2 + case_corner_radius + left_height_remaining/10, pill_height]) rotate([0, 0, 90]) pill();
    translate([-case_outer_width/2 + case_wall_thickness, -case_outer_height/2 + case_corner_radius + left_height_remaining/2, pill_height]) rotate([0, 0, 90]) pill();
    translate([-case_outer_width/2 + case_wall_thickness, -case_outer_height/2 + case_corner_radius + left_height_remaining*9/10, pill_height]) rotate([0, 0, 90]) pill();

    // one pill on diagonal at top
    // TODO something still isn't quite right about this calculation - if the
    // inputs change, this pill ends up in the wrong spot
    angle = atan((case_top_corner_vertical_offset) / (case_top_corner_horizontal_offset));
    half_distance = (case_top_corner_vertical_offset - case_wall_thickness) / sin(angle) / 2;
    translate([-case_outer_width/2 + case_top_corner_horizontal_offset + case_corner_radius, case_outer_height/2 - case_corner_radius - case_wall_thickness, pill_height])
        rotate([0, 0, angle])
        translate([-half_distance, case_corner_radius, 0])
        pill();

}

dovetail_height = 7;
dovetail_width = 15;
dovetail_length = 5;
dovetail_tolerance = 0.1;
dovetail_bump_radius = 2.5;
dovetail_bump_height = 0.6;

module male_dovetail_2d(width, length, bump_height, tolerance) {
    polygon(points = [
        [-width/6, -length/2],
        [-width/4, length/2-bump_height-tolerance-0.01],
        [width/4, length/2-bump_height-tolerance-0.01],
        [width/6, -length/2],
    ]);
}
module male_dovetail(height=dovetail_height, width=dovetail_width, length=dovetail_length, tolerance=dovetail_tolerance, bump_radius=dovetail_bump_radius, bump_height=dovetail_bump_height) {
    union() {
        linear_extrude(h=height) male_dovetail_2d(width=width, length=length, bump_height=bump_height, tolerance=tolerance);
        if (bump_height > 0)
            translate([0, length/2 - bump_radius - tolerance, height/2]) sphere(r=bump_radius);
    }
}

module female_dovetail_2d(height, width, length, tolerance, bump_height) {
    difference() {
        polygon(points = [
            [-width/2, -length/2 + tolerance],
            [-width/2, length/2],
            [width/2, length/2],
            [width/2, -length/2 + tolerance],
        ]);
        offset(r=tolerance) male_dovetail_2d(width=width, length=length, bump_height=bump_height, tolerance=tolerance);
    }
}
module female_dovetail(height=dovetail_height, width=dovetail_width, length=dovetail_length, tolerance=dovetail_tolerance, bump_radius=dovetail_bump_radius, bump_height=dovetail_bump_height) {
    difference() {
        linear_extrude(h=height) female_dovetail_2d(width=width, length=length, tolerance=tolerance, bump_height=bump_height);
        if (bump_height > 0)
            translate([0, length/2 - bump_radius, height/2]) sphere(r=bump_radius);
    }
}

module mirror_and_copy(v) {
    union() {
        children();
        mirror(v) children();
    }
}
spool_holder_length = 215;
spool_holder_bearing_separation = 100;
spool_holder_min_wall_thickness = 3;
spool_holder_max_wall_thickness = 5;
spool_holder_max_radius = bearing_outer_diameter/2 + 4;
spool_holder_bearing_height = spool_holder_max_radius + 3;
spool_holder_max_width = 85;
spool_holder_bearing_inner_support_offset = 1;
spool_holder_roller_length = spool_holder_max_width - spool_holder_min_wall_thickness*2 - spool_holder_bearing_inner_support_offset*2;
spool_holder_support_width = 20;
module spool_holder_base() {
    mirror_and_copy([0, 1, 0])
    union() {
        cutout_radius = 100;
        small_radius = bearing_inner_support_diameter/2;
        cutout_z_offset = sqrt((cutout_radius + small_radius)^2 - (spool_holder_bearing_separation/2)^2) - cutout_radius;
        cutout_tangent_angle = asin(spool_holder_bearing_separation/2/(cutout_radius + small_radius));
        guardrail_radius = spool_holder_max_radius + 10; // stick up 1cm beyond rollers

        difference() {
            union() {
                difference() {
                    union() {
                        hull() {
                            translate([0, spool_holder_bearing_separation/2, spool_holder_bearing_height]) rotate([0, 90, 0]) cylinder(r=bearing_inner_support_diameter/2, h=spool_holder_max_wall_thickness);
                            // end of holder
                            translate([0, spool_holder_length/2-5, 5]) rotate([0, 90, 0]) cylinder(r=5, h=spool_holder_max_wall_thickness);
                            translate([0, spool_holder_bearing_separation/2 - bearing_inner_support_diameter/2, 0]) cube([spool_holder_max_wall_thickness, 0.01, 0.01]);
                        }
                        cube_height = spool_holder_bearing_height + small_radius * cos(cutout_tangent_angle);
                        translate([0, -0.01, 0]) cube([spool_holder_max_wall_thickness, spool_holder_bearing_separation/2 + 0.01, cube_height]);
                    }
                    // cutout big top radius for spool
                    translate([-0.01, 0, cutout_radius + spool_holder_bearing_height + cutout_z_offset]) rotate([0, 90, 0]) cylinder(r=cutout_radius, h=spool_holder_max_wall_thickness+0.02);
                }

                // add guardrails for spools
                translate([0, spool_holder_bearing_separation/2, spool_holder_bearing_height])
                rotate([cutout_tangent_angle, 0, 0])
                intersection() {
                    union() {
                        translate([0, 0, guardrail_radius - bearing_inner_support_diameter/2]) rotate([0, 90, 0]) cylinder(d=bearing_inner_support_diameter, h=spool_holder_max_wall_thickness);
                        translate([0, -bearing_inner_support_diameter/2, -bearing_inner_support_diameter/2]) cube([spool_holder_max_wall_thickness, bearing_inner_support_diameter, guardrail_radius]);
                    }
                    hull() {
                        translate([0, 0, guardrail_radius - bearing_inner_support_diameter/2]) sphere(d=bearing_inner_support_diameter);
                        translate([0, 0, -bearing_inner_support_diameter]) sphere(d=bearing_inner_support_diameter);
                    }
                }
            }

            // cutout space for roller in side
            translate([spool_holder_min_wall_thickness, spool_holder_bearing_separation/2, spool_holder_bearing_height]) rotate([0, 90, 0]) cylinder(r=spool_holder_max_radius + 1, h=spool_holder_max_wall_thickness-spool_holder_min_wall_thickness + 0.01);
        }


        // add the dovetail and dovetail/strut rest
        spool_holder_base_dovetail_height = 9.5;
        spool_holder_base_dovetail_rotation = 14.5;
        spool_holder_base_dovetail_y_offset = spool_holder_support_width*11/20;
        translate([spool_holder_max_wall_thickness + dovetail_length/2, spool_holder_bearing_separation/2 + spool_holder_max_radius + spool_holder_base_dovetail_y_offset, spool_holder_base_dovetail_height]) rotate([0, -spool_holder_base_dovetail_rotation, -90]) male_dovetail();
        translate([0, spool_holder_bearing_separation/2 + spool_holder_max_radius + spool_holder_base_dovetail_y_offset, spool_holder_base_dovetail_height+0.01]) rotate([-spool_holder_base_dovetail_rotation, 0, 0]) translate([0, -spool_holder_support_width/2, -2]) cube([spool_holder_max_wall_thickness + 2, spool_holder_support_width, 2]);
        // Add bearing offset to prevent rubbing
        translate([spool_holder_min_wall_thickness - 0.01, spool_holder_bearing_separation/2, spool_holder_bearing_height]) rotate([0, 90, 0]) cylinder(r=bearing_inner_support_diameter/2, h=spool_holder_bearing_inner_support_offset);
        // Add axle for bearing to ride on
        translate([spool_holder_min_wall_thickness - 0.01, spool_holder_bearing_separation/2, spool_holder_bearing_height]) rotate([0, 90, 0]) cylinder(r=bearing_inner_diameter/2, h=bearing_width);
    }
}

module spool_holder_strut() {
    strut_length = spool_holder_max_width - spool_holder_max_wall_thickness*2;
    cutout_width = 12;
    cutout_length = max(0, strut_length/2 - dovetail_length - 7.5);
    dessicant_support_diameter = min(3, (spool_holder_support_width-cutout_width)/2);
    mirror_and_copy([1, 0, 0])
    union() {
        difference() {
            // the main block
            translate([-0.01, 0, 0]) cube([strut_length/2 + 0.01, spool_holder_support_width, dovetail_height]);
            // cutout for where we'll add the dovetail back in
            translate([strut_length/2 - dovetail_length + dovetail_tolerance + 0.01, (spool_holder_support_width-dovetail_width)/2+0.02, -0.01]) cube([dovetail_length, dovetail_width-0.02, dovetail_height+0.02]);
            // cutout in middle for space we don't need filled in
            translate([2.5, (spool_holder_support_width-cutout_width)/2, -0.01]) cube([cutout_length, cutout_width, dovetail_height + 0.02]);
        }
        translate([2.5 + cutout_length/2, (spool_holder_support_width-cutout_width)/4, dovetail_height-0.01]) cylinder(d=dessicant_support_diameter, h=20.01);
        translate([strut_length/2 -dovetail_length/2 + dovetail_tolerance, spool_holder_support_width/2, 0]) rotate([0, 0, 90]) female_dovetail();
    }
}

module spool_holder_roller() {
    bevel_length = 2;

    rotate_extrude()
    rotate([0, 0, -90])
    mirror_and_copy([1, 0, 0])
    polygon([
        [-0.01, bearing_outer_diameter/2-bevel_length],
        [spool_holder_roller_length/2 - bearing_width - bevel_length, bearing_outer_diameter/2-bevel_length],
        [spool_holder_roller_length/2 - bearing_width, bearing_outer_diameter/2],
        [spool_holder_roller_length/2, bearing_outer_diameter/2],
        [spool_holder_roller_length/2, spool_holder_max_radius],
        [spool_holder_roller_length/2-bevel_length, spool_holder_max_radius-bevel_length],
        [-0.01, spool_holder_max_radius-bevel_length],
    ]);
}

part = "case";
if (part == "case") {
    case(mirrored=false);
} else if (part == "case_mirrored") {
    case(mirrored=true);
} else if (part == "lid") {
//    rotate([0, 180, 0])
    lid(mirrored=false);
} else if (part == "lid_mirrored") {
//    rotate([0, 180, 0])
    lid(mirrored=true);
} else if (part == "hanger") {
    rotate([0, 90, 0])
    case_hanger();
} else if (part == "hanger_nut") {
    case_hanger_nut();
} else if (part == "pulley") {
    pulley();
} else if (part == "spool_holder_base") {
    rotate([0, -90, 0]) spool_holder_base();
} else if (part == "spool_holder_strut") {
    spool_holder_strut();
} else if (part == "spool_holder_roller") {
    spool_holder_roller();
} else {
    case_lid_hanger_cutout();
//    assert(false, "Invalid part requested");
}
