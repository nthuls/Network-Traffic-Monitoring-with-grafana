export {
    redef record Conn::Info += {
        orig_h_asn: geo_autonomous_system &log &optional;
        resp_h_asn: geo_autonomous_system &log &optional;
        orig_h_location: geo_location &log &optional;
        resp_h_location: geo_location &log &optional;
    };
}

event connection_state_remove(c: connection) &priority=0
{
    local orig: addr = c$conn$id$orig_h;

    if ( !Site::is_private_addr(orig) ) {
        c$conn$orig_h_asn = lookup_autonomous_system(orig);

        local orig_location = lookup_location(orig);
        if ( orig_location?$country_code ) {
            c$conn$orig_h_location = orig_location;
        }
    }

    local resp: addr = c$conn$id$resp_h;

    if ( !Site::is_private_addr(resp) ) {
        c$conn$resp_h_asn = lookup_autonomous_system(resp);

        local resp_location = lookup_location(resp);
        if ( resp_location?$country_code ) {
            c$conn$resp_h_location = resp_location;
        }
    }
}
