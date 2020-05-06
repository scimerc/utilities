# @include "nucleocode.awk"
# @include "genotype.awk"
function gflipper(a1,a2,b1,b2)
{
  gen_a = genotype(nucleocode(a1),nucleocode(a2));
  gen_ac = genotype(comp_nucleocode(a1),comp_nucleocode(a2));
  gen_b = genotype(nucleocode(b1),nucleocode(b2));
  gen_bc = genotype(comp_nucleocode(b1),comp_nucleocode(b2));
  if ( gen_a == gen_bc && gen_ac == gen_b && gen_a != gen_ac && gen_b != gen_bc ) print ( $0 );
}
