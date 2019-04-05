@rem = '--*-Perl-*--
cmd /c perl ".\D3D11ConstantHeaderGen.bat" %1 %2 %3 %4 %5 %6 %7 %8 %9
goto endofperl
@rem ';
#-----------------------------------------------------------------------------
# This script parses the D3D11 constant listing file and 
# generates a C header file that #defines constants
# 
# The constant listing file is the place that numerical constants
# get published to both the spec and to D3D11 headers.
#
# See the constant listing file for a comment describing the 
# layout.
#
# Usage:
# D3D11ConstantHeaderGen.bat outputFile
#-----------------------------------------------------------------------------
#-----------------------------------------------------------------------------
#
# Parse command line
#
$inFile = "D3D11Constants.dat";
$outFile = shift (@ARGV);

if( $inFile eq "" ) {die "No input specified\n";}
if( $outFile eq "" ) {die "No output specified\n";}

#-----------------------------------------------------------------------------
#
# Parse input file and generate output file
#

%D3D11Constant;
%D3D11ConstantType;
%D3D11ConstantDeclaration;
    
# The subroutine below parses the constant file into a hash.
# That's really unnecessary for the purpose of this
# script, however it allows me to just cut & paste
# the parsing from the HTML processing script.

# This subroutine is cut&pasted from postproc.pl.
sub ParseConstantFile
{
    my ($ConstFile) = @_;
    $ConstantPrefix = "###";
    open(CONSTLIST,$ConstFile) || die("Can't open file $ConstFile");
    while(<CONSTLIST>) {
        if(/^\s*(\w+)\s*=/)
        {
            if(undef!=$D3D11Constant{$1})
            {
                die("$1 defined multiple times!");
            }
        }
        if(/^\s*(\w+)\s*=\s*(0x([a-f]|[A-F]|[0-9])+)\s+/)  # hex
        {
            $D3D11Constant{"$1"} = "$2";
            $D3D11ConstantType{"$1"} = "UINT";
        }
        elsif(/^\s*(\w+)\s*=\s*(-([0-9])+)\s+/)  # signed integer
        {
            $D3D11Constant{"$1"} = "$2";
            $D3D11ConstantType{"$1"} = "INT";
        }
        elsif(/^\s*(\w+)\s*=\s*(([0-9])+)\s+/)  # unsigned integer
        {
            $D3D11Constant{"$1"} = "$2";
            $D3D11ConstantType{"$1"} = "UINT";
        }
        elsif(/^\s*(\w+)\s*=\s*([+-]?(\d+\.\d+|\d+\.|\.\d+|\d+)([eE][+-]?\d+)?)\s+/)  # double (no trailing f)
        {
            $D3D11Constant{"$1"} = "$2";
            $D3D11ConstantType{"$1"} = "double";
        }
        elsif(/^\s*(\w+)\s*=\s*([+-]?(\d+\.\d+|\d+\.|\.\d+|\d+)([eE][+-]?\d+)?(f)?)\s+/)  # float (trailing f)
        {
            $D3D11Constant{"$1"} = "$2";
            $D3D11ConstantType{"$1"} = "float";
        }
        elsif(/^\s*(\w+)\s*=\s*(\w+)\s+/) # word
        {
            if(!exists($D3D11Constant{"$2"}))
            {
                die("$1 being assigned undefined value $2!");
            }
            else
            {
                $D3D11Constant{"$1"} = $D3D11Constant{"$2"};   
                $D3D11ConstantType{"$1"} = $D3D11ConstantType{"$2"};
            }        
        }
        elsif(/^\s*(\w+)\s*=/)
        {
            die("Unrecognized or unsupported assignement of $1 in constant list.");
        }
    }
    close(CONSTLIST);    
}

sub PrintConstantList
{
    my ($OutputFile) = @_;
    open(OUTPUTFILE,">".$OutputFile) || die("Can't open output file $OutputFile");
    @keys = sort keys %D3D11Constant;
    print OUTPUTFILE "// NOTE: The following constants are generated from the D3D11 hardware spec.  Do not edit these values directly.\n";
    print OUTPUTFILE "#ifndef _D3D11_CONSTANTS\n";
    print OUTPUTFILE "#define _D3D11_CONSTANTS\n";
    foreach(@keys)
    {
        if( ($D3D11ConstantType{$_} eq "float") |
            ($D3D11ConstantType{$_} eq "double") )
        {
            print OUTPUTFILE "#define $_\t( $D3D11Constant{$_} )\n";
        }
        else
        {
            print OUTPUTFILE "const $D3D11ConstantType{$_} $_ = $D3D11Constant{$_};\n";
        }
    }   
    print OUTPUTFILE "#endif\n";
    close(OUTPUTFILE);    
}
   
ParseConstantFile($inFile);
PrintConstantList($outFile);

#-----------------------------------------------------------------------------
__END__
:endofperl


