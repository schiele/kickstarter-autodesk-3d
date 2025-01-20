/*
   Copyright 2025 Robert Schiele

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.

   The design is derived from
   https://github.com/kickstarter/kickstarter-autodesk-3d
   which is Copyright 2018 Autodesk and available under the same license.

   This model attempts to stay as close to the original as possible.
   There are the following minor differences though:
   - Cylinders and other roundings are split in a higher number of
     segments. The precision can be controlled by the $fa and $fs variables.
   - Some incorrect labeling on the tolerance test have been corrected.
   - The positioning of the text on the overhang tests was slightly adjusted
     since the original text was not positioned in a consistent way.
   - The fillet at the achor point of the overhead test is designed in a
     slightly different way since this is easier to describe in OpenSCAD and
     also feels more consistent.
   - The "OS" text has been added to the model version to clearly mark this
     not to be the original model.

   All of those changes should not have any significant impact on the tests.
   If you want to compare the results with existing results of other printers
   you should use the original model though to be on the safe side.

   This model was designed for easier integration with OpenSCAD and to be used
   in a more programmatic context. Maintaining and adapting sources with
   slightly more than 100 lines of code also seems easier than doing this with
   a 2.2MB compressed binary file we need to open in a proprietary software
   and therefore no easy way to version control the changes.
*/

use <polyround.scad>

$fa=1;
$fs=0.2;

// #import("ksr_fdmtest_v4.stl");

module txt(text, size, angle, pos) translate(pos) rotate(angle)
    text(text, size, "Arial Black", halign="center", valign="center");

module base() difference() {
    linear_extrude(10, convexity=3) polyround([
        [73, 2, 2], [73, 63, 2], [42, 63, 2], [38, 22, -2], [7, 22, -2],
        [7, 56, -2], [15, 60, 2], [15, 68, 2], [2, 68, 2], [2, 2, 2]]);
    linear_extrude(12, center=true) polyround([
        [66, 24, 4], [66, 56, 4], [49, 56, 4], [49, 24, 4]]);
    rotate([0, 90, 0]) cylinder(100, r=1, $fn=4);
    translate([75, 0, 0]) rotate([-90, 0, 0]) cylinder(100, r=1, $fn=4);
    translate([35, 65, 0]) rotate([0, 90, 0]) cylinder(100, r=1, $fn=4);
    translate([38, 20, 0]) rotate([-90, 0, 0]) cylinder(100, r=3, $fn=4);
}

function ol(i, o) = i?ol(i-1, o)+tan(o[i-1]):0;

module overhang(o=[45, 30, 20, 15]) {
    for(i=[0:3]) translate([0, 12*i, 12*ol(i, o)]) mirror([0, 1, 0])
        rotate([90-o[i], 0, 0]) difference() {
            translate([0, 0, i?-5*sin((o[i-1]-o[i])/2):0])
                linear_extrude(12/cos(o[i])+(i?5*sin((o[i-1]-o[i])/2):0)+
                               (i+1<len(o)?5*sin((o[i]-o[i+1])/2):0))
                    polyround([[-21/2, 2, 2], [21/2, 2, 2],
                               [25/2, 5, 0], [-25/2, 5, 0]]);
            translate([0, 5, 6/cos(o[i])+(i?0:2)]) rotate([90, 0, 0])
                linear_extrude(1.6, center=true)
                    txt(str(o[i]), 5.76, 0, [0, 0]);
        }
    for(i=[0, 1]) mirror([i, 0, 0]) translate([14.5, 0, 0]) intersection() {
        multmatrix([[1, 0, 0, 0], [0, 1, 0, 0], [0, tan(o[0]), 1, 0]])
            rotate(180) translate([0, -2, 0]) rotate_extrude(angle=90)
                scale([1, 1/cos(o[0])]) {
                    translate([2, 2]) square([4, 3]);
                    translate([4, 0]) square(2);
                    translate([4, 2]) circle(2);
                }
        translate([-10, -1, 0]) cube(10);
    }
}

module needles() rotate(90) {
    intersection() {
        linear_extrude(52) polyround([
            [2, 2, 2], [40, 0, 0], [40, 40, 0], [0, 40, 0]]);
        union() {
            translate([0, 0, 50]) cube([40, 40, 2]);
            translate([0, 0, 2]) cube([12, 12, 50]);
            for(i=[[1, 40, 90], [40, 40, 135], [40, 1, 180]])
                translate([i.x, i.y, 50]) rotate([0, 30, -i.z])
                    translate([0, -1, 0]) cube([50, 2, 25]);
        }
    }
    for(x=[5:15:35], y=[5:15:35]) translate([x, y, 52])
        linear_extrude(40, scale=0.3) square(2, center=true);
}

module dimensions() translate([0, 0, 8]) for(i=[1:5])
    cylinder(26-4*i, d=5*i);

module bridge() rotate([90, 0, 90]) linear_extrude(5)
    polygon([[9, 0], [70, 0], [70, 19], [9, 19],
             for(i=[0:4]) [59-i*10, 4+i*3],
             for(i=[0:4]) [62, 4+i*3],
             for(i=[0:4]) [62, 5+i*3],
             for(i=[0:4]) [52-i*10, 5+i*3],
             for(i=[0:4]) [52-i*10, 4],
             for(i=[0:4]) [59-i*10, 4]], [
             [0, 1, 2, 3],
             for(i=[0:4]) [for(j=[0:5]) 4+i+j*5]]);

module bridgecut() {
    translate([-1, 52, 1]) cube(20);
    translate([-95, 12, 1]) cube(100);
}

module tolerance()
    for(i=[2:6]) translate([i*10-5, 12, 0]) {
        translate([0, 0, 0.5]) cylinder(14.5, r=4-i/10);
        cylinder(0.5, r1=3.5-i/10, r2=4-i/10);
    }

module tolerancecut()
    for(i=[2:6]) translate([i*10-5, 12, -1]) {
        cylinder(15, r=4);
        cylinder(2, r1=6, r2=4);
    }

module tolerancetext() for(i=[2:6])
    txt(str("0.",i), 3.24, 45, [i*10-10.7, 4.53]);

module ringingcut() {
    for(i=[-10:10]) translate([2*i-0.25, -1, 1])
        cube([0.5, 2, (i%5)?1.5:2.5]);
    translate([-0.25, -0.5, 1]) cube([0.5, 1, 6]);
}

render() {
    difference() {
        base();
        bridgecut();
        for(j=[[37.5, 0, 0], [75, 37.5, 90]]) translate([j.x, j.y, 0])
            rotate(j.z) ringingcut();
        tolerancecut();
        translate([0, 0, 10]) linear_extrude(1.6, center=true) {
            txt("v4", 7.2, 90, [46.35, 27.4]);
            txt("OS", 3.6, 90, [44.57, 36.8]);
            tolerancetext();
            translate([67, 20]) rotate(90) {
                for(r=[0, 90]) rotate(r) hull() for(i=[0, 9.4])
                    translate([i, 0]) circle(0.6);
                txt("X", 2.89, 0, [10.94, 3.44]);
                txt("Y", 2.89, 0, [3.56, 10.82]);
            }
        }
    }
    translate([57.5, 47.5, 0]) dimensions();
    bridge();
    tolerance();
    translate([22.5, 20, 0]) overhang();
    translate([75, 0, 0]) needles();
}
