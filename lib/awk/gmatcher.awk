# @include "nucleocode.awk"
# @include "genotype.awk"
function gmatcher(a1,a2,b1,b2)
{
  gen_a = genotype(nucleocode(a1),nucleocode(a2));
  gen_b0 = genotype(nucleocode(b1),nucleocode(b2));
  gen_b1 = genotype(comp_nucleocode(b1),comp_nucleocode(b2));
  if ( gen_a == gen_b0 || gen_a == gen_b1 ) print( $0 );
}

