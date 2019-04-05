@rem = '--*-Perl-*--
cmd /c perl ".\buildit.bat" %1 %2 %3 %4 %5 %6 %7 %8 %9
goto endofperl
@rem ';
#####################################################################


$SystemEcho = 0;
#####################################################################
sub buildtarget
{
    my ($targetdir, $options) = @_;
    if (! -e $targetdir) { mysystem("mkdir ".$targetdir); }
    else {mysystem("del /q ".$targetdir."\\D3D11_3_FunctionalSpec.htm");}
    mysystem("perl postproc.pl D3D11_3_FunctionalSpec.htm D3D11Constants.dat ".$options." >".$targetdir."\\D3D11_3_FunctionalSpec.htm");
#    mysystem("copy D3D11_3_AALineRast.png ".$targetdir);
#    mysystem("copy D3D11_3_BC.png ".$targetdir);
#    mysystem("copy D3D11_3_BC1.png ".$targetdir);
#    mysystem("copy D3D11_3_BC2.png ".$targetdir);
#    mysystem("copy D3D11_3_BC3.png ".$targetdir);
#    mysystem("copy D3D11_3_BC4S.png ".$targetdir);
#    mysystem("copy D3D11_3_BC4U.png ".$targetdir);
#    mysystem("copy D3D11_3_BC5S.png ".$targetdir);
#    mysystem("copy D3D11_3_BC5U.png ".$targetdir);
#    mysystem("copy D3D11_3_BC6H.png ".$targetdir);
#    mysystem("copy D3D11_3_BC6H_shapes.png ".$targetdir);
#    mysystem("copy D3D11_3_BC6H_bit_fields_packed_compressed_endpts.png ".$targetdir);
#    mysystem("copy D3D11_3_BC6H_transform_inverse_two.png ".$targetdir);
#    mysystem("copy D3D11_3_BC7_mode0.png ".$targetdir);
#    mysystem("copy D3D11_3_BC7_mode1.png ".$targetdir);
#    mysystem("copy D3D11_3_BC7_mode2.png ".$targetdir);
#    mysystem("copy D3D11_3_BC7_mode3.png ".$targetdir);
#    mysystem("copy D3D11_3_BC7_mode4.png ".$targetdir);
#    mysystem("copy D3D11_3_BC7_mode5.png ".$targetdir);
#    mysystem("copy D3D11_3_BC7_mode6.png ".$targetdir);
#    mysystem("copy D3D11_3_BC7_mode7.png ".$targetdir);
#    mysystem("copy D3D11_3_BC7_2Subsets.png ".$targetdir);
#    mysystem("copy D3D11_3_BC7_3Subsets.png ".$targetdir);
#    mysystem("copy D3D11_3_ComputeDispatchExample.png ".$targetdir);
#    mysystem("copy D3D11_3_CorePipe1.png ".$targetdir);
#    mysystem("copy D3D11_3_CorePipe2.png ".$targetdir);
#    mysystem("copy D3D11_3_CoordSystem.png ".$targetdir);
#    mysystem("copy D3D11_3_FixedPoint.png ".$targetdir);
#    mysystem("copy D3D11_3_GSInputs1.png ".$targetdir);
#    mysystem("copy D3D11_3_GSInputs2.png ".$targetdir);
#    mysystem("copy D3D11_3_GSInputs3.png ".$targetdir);
#    mysystem("copy D3D11_3_GSOutputs.png ".$targetdir);
#    mysystem("copy D3D11_3_HullShader.png ".$targetdir);
#    mysystem("copy D3D11_3_IAExample1.png ".$targetdir);
#    mysystem("copy D3D11_3_IAExample2.png ".$targetdir);
#    mysystem("copy D3D11_3_IAExample3.png ".$targetdir);
#    mysystem("copy D3D11_3_LineRast.png ".$targetdir);
#    mysystem("copy D3D11_3_MulticoreOverview.png ".$targetdir); 
#    mysystem("copy D3D11_3_MSAAGrid.png ".$targetdir);
#    mysystem("copy D3D11_3_MSAAPatterns_2_4.png ".$targetdir);
#    mysystem("copy D3D11_3_MSAAPatterns_8_16.png ".$targetdir);
#    mysystem("copy D3D11_3_MSAARast.png ".$targetdir); 
#    mysystem("copy D3D11_3_PointRast.png ".$targetdir);
#    mysystem("copy D3D11_3_R11G11B10_FLOAT.png ".$targetdir);
#    mysystem("copy D3D11_3_RGBE.png ".$targetdir);
#    mysystem("copy D3D11_3_ResourceTypes1.png ".$targetdir);
#    mysystem("copy D3D11_3_ResourceTypes2.png ".$targetdir);
#    mysystem("copy D3D11_3_TexCoords.png ".$targetdir);
#    mysystem("copy D3D11_3_Topology1.png ".$targetdir);
#    mysystem("copy D3D11_3_TriRast.png ".$targetdir);
#    mysystem("copy D3D11_3_Formats_FL9_1.xls ".$targetdir);
#    mysystem("copy D3D11_3_Formats_FL9_2.xls ".$targetdir);
#    mysystem("copy D3D11_3_Formats_FL9_3.xls ".$targetdir);
#    mysystem("copy D3D11_3_Formats_FL10_0.xls ".$targetdir);
#    mysystem("copy D3D11_3_Formats_FL10_1.xls ".$targetdir);
#    mysystem("copy D3D11_3_Formats_FL11_0.xls ".$targetdir);
#    mysystem("copy D3D11_3_Formats_FL11_1.xls ".$targetdir);
#    mysystem("copy tessellator.hpp ".$targetdir);
#    mysystem("copy tessellator.cpp ".$targetdir);
}

#buildtarget("internal","");
#buildtarget("ddk","-noint -noapi");
#buildtarget("gab","-noint -noddi");
#buildtarget("nodel","-nodel10To11 -noint");
buildtarget("..\\..\\","-noint");

#####################################################################
#
#   wrapper for system function
#
sub mysystem {
    local($str) = @_;
    local($ret);
    if ($SystemEcho) { print "SYSTEM:<$str>\n"; }
    $ret = system $str;
    $ret >>= 8;
    $SystemReturn = $ret;
    return $ret;
}
#####################################################################
__END__
:endofperl

