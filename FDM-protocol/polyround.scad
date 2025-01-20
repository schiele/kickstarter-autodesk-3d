// polyround --- polygon with rounded corners
// Copyright (C) 2024-2025  Robert Schiele <rschiele@gmail.com>
//
// This work is licensed under the Creative Commons Attribution 4.0
// International License. To view a copy of this license, visit 
// http://creativecommons.org/licenses/by/4.0/.

/*

    You use polyround in the same way as you would use polygon,
    with the exception that all points for the corners have a
    third "coordinate" resembling the radius used to round the
    corner. If this radius is 0 for a point the behavior of
    polyround is exactly identical as polygon. If the radius is
    a positive number it will draw the outline around a circle
    with the specified radius located at the position of the
    coordinates specified, forming a convex rounded corner. For
    concave rounded corners you specify the radius as a negative
    number.
    
    Additionally you may invoke polyround_extrude with the same
    parameters to extrude a 2D object around the outline of the
    corresponding polyround object.
    
    Whenever using this package you need to use them inside your
    OpenSCAD code with the statement
    
    use <polyround.scad>

    Once you do that you can use polyround with the same syntax as you would use polygon. Find some examples at the
    bottom of this file.

 */

// minimum angle for a fragment
$fa=1;
// minimum size of a fragment
$fs=0.5;

function frags(r, a=360) =
    ceil(($fn>0 ? ($fn>=3?$fn:3) :
                  ceil(max(min(360/$fa,r*2*PI/$fs),5)))*a/360);

function polyround_int(v) =
    let(l=len(v),
        av=[for(i=[1:l]) let(pd=v[i-1]-v[(i+l-2)%l])
                atan2(-pd.x, pd.y) +
                atan2(-pd.z, sqrt(pd.x^2+pd.y^2-pd.z^2))])
    [for(i=[0:l-1])
        let(a1=av[i], a2=av[(i+1)%l], s=sign(v[i].z),
            a2c=a2+(a2*s<a1*s?360:0)*s, al=abs(a2c-a1))
            for(a=s?[a1:s*al/frags(abs(v[i].z), al):a2c]:[a1])
                [v[i].x+v[i].z*cos(a), v[i].y+v[i].z*sin(a)]];

module polyround(points=undef, paths=undef, convexity=1,
                 debug=false) {
    let(v=paths?[for(p1=paths) [for(p2=p1) points[p2]]]:[points])
        difference() {
            polygon(polyround_int(v[0]), convexity=convexity);
            for(vi=[1:1:len(v)-1])
                polygon(polyround_int(v[vi]),
                        convexity=convexity);
        }
    %if(debug) for(i=points) translate([i.x, i.y]) circle(abs(i.z));
}

module polyround_extrude_int(v, convexity)
    let(l=len(v),
        av=[for(i=[1:l]) let(pd=v[i-1]-v[(i+l-2)%l])
                atan2(-pd.x, pd.y) +
                atan2(-pd.z, sqrt(pd.x^2+pd.y^2-pd.z^2))])
    for(i=[0:l-1])
        let(a1=av[i], a2=av[(i+1)%l], s=sign(v[i].z),
            a2c=a2+(a2*s<a1*s?360:0)*s,
            vd=v[(i+l-1)%l]-v[i]) {
            translate([v[i].x, v[i].y]) rotate(a1)
                rotate_extrude(angle=a2c-a1,
                               convexity=convexity)
                    translate([v[i].z, 0, 0]) children();
            translate([v[i].x+v[i].z*cos(a1),
                       v[i].y+v[i].z*sin(a1)])
                rotate([90, 0, a1])
                    linear_extrude(norm([vd.x+vd.z*cos(a1),
                                         vd.y+vd.z*sin(a1)]),
                                   convexity=convexity)
                        children();
        }

module polyround_extrude(points=undef, paths=undef,
                         convexity=1, debug=false) {
    let(v=paths?[for(p1=paths) [for(p2=p1) points[p2]]]:[points])
        for(vi=[0:1:len(v)-1])
            polyround_extrude_int(v[vi], convexity)
                children();
    %if(debug) for(i=points) translate([i.x, i.y]) circle(abs(i.z));
}

polyround([[-10, -5, 15], [15, 15, -5], [40, 15, 10], [20, 45, 10]], debug=true);

polyround([[20, -20, 2], [30, -20, 2], [40, -20, 2], [50, -20, 2],
         [20, -30, 2], [30, -30, 2], [40, -30, 2], [50, -30, 2],
         [20, -40, 2], [30, -40, 2], [40, -40, 2], [50, -40, 2],
         [20, -50, 2], [30, -50, 2], [40, -50, 2], [50, -50, 2]],
        [[3, 0, 12, 15], [6, 5, 9, 10]], debug=true);
        
translate([10, -10])
polyround_extrude([
    [0, 0, 1],
    [10, 0, 1],
    [10, 10, 1],
    [0, 10, 1],
]) circle(1);
