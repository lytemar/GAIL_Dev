from meanYParam import MeanYParam, default_random_generator
from CubMeanParam import CubMeanParam
import inspect
import pytest


@pytest.mark.parametrize(
    'property, default_value, comment', [
        ('alpha', 0.01, '  Comment: default alpha = 0.01'),
        ('absTol', 0.01, '  Comment: default absTol = 0.01'),
        ('nSig', 1000, '  Comment: default nSig = 1000'),
        ('relTol', 0, '  Comment: default relTol = 0'),
        ('Y', default_random_generator, '  Comment: default Y = Uniform Square Random generator')
            ('inflate', 1.2, '  Comment: default inflate = 1.2')
    ])
def test_defaults(property, default_value, comment):
    myp = MeanYParam()
    assert getattr(myp, property) == default_value


@pytest.mark.parametrize(
    'alpha,  comment', [
        (-0.1, '  Comment: negative alpha'),
        ('0.1', '  Comment: non-numeric alpha'),
        (2, '  Comment: greater than 1'),
        ('', '  Comment: empty alpha'),
        (None, '  Comment: null alpha '),
    ])
def test_alpha_excepetions(alpha, comment):
    with pytest.raises(Exception):
        myp = MeanYParam(alpha=alpha)


@pytest.mark.parametrize(
    'absTol,  comment', [
        (-0.1, '  Comment: negative absTol'),
        ('0.1', '  Comment: non-numeric absTol'),
        ('', '  Comment: empty absTol'),
        (None, '  Comment: null absTol '),
    ])
def test_absTol_excepetions(absTol, comment):
    with pytest.raises(Exception):
        myp = MeanYParam(absTol=absTol)


@pytest.mark.parametrize(
    'nSig,  comment', [
        (-0.1, '  Comment: negative nSig'),
        ('0.1', '  Comment: non-numeric nSig'),
        ('', '  Comment: empty nSig'),
        (None, '  Comment: null nSig '),
    ])
def test_nSig_excepetions(nSig, comment):
    with pytest.raises(Exception):
        myp = MeanYParam(nSig=nSig)


@pytest.mark.parametrize(
    'relTol,  comment', [
        (-0.1, '  Comment: negative relTol'),
        ('0.1', '  Comment: non-numeric relTol'),
        ('', '  Comment: empty relTol'),
        (None, '  Comment: null relTol '),
    ])
def test_relTol_excepetions(relTol, comment):
    with pytest.raises(Exception):
        myp = MeanYParam(relTol=relTol)


@pytest.mark.parametrize(
    'Y,  comment', [
        ('5', '  Comment: Y not String'),
        ([5, 6, 6], '  Comment: Y not list'),
        (45, '  Comment: Y not numeric'),
    ])
def test_y(Y, comment):
    with pytest.raises(Exception):
        myp = MeanYParam(Y=Y)


@pytest.mark.parametrize(
    'inflate,  comment', [
        ('5', '  Comment: inflate not String'),
        ('', '  Comment: empty inflate'),
    ])
def test_inflate(inflate, comment):
    with pytest.raises(Exception):
        myp = CubMeanParam(inflate=inflate)


@pytest.mark.parametrize(
    'nInit,  comment', [
        ('5', '  Comment: nInit not String'),
        ('', '  Comment: empty nInit'),
        (-1.1, '  Comment: nInit negative nSig'),
        (2.1, '  Comment: nInit integer')
    ])
def test_nInit(nInit, comment):
    with pytest.raises(Exception):
        myp = CubMeanParam(nInit=nInit)


@pytest.mark.parametrize(
    'nMax,  comment', [
        ('5', '  Comment: nMax not String'),
        ('', '  Comment: empty nMax'),
        (-1.1, '  Comment: nMax negative nSig'),
        (2.1, '  Comment: nMax integer')
    ])
def test_nMax(nMax, comment):
    with pytest.raises(Exception):
        myp = CubMeanParam(nMax=nMax)


@pytest.mark.parametrize(
    'nMu,  comment', [
        ('5', '  Comment: nMu not String'),
        ('', '  Comment: empty nMu'),
        (-1.1, '  Comment: nMu negative nSig'),
        (2.1, '  Comment: nMu integer')
    ])
def test_nMu(nMu, comment):
    with pytest.raises(Exception):
        myp = CubMeanParam(nMu=nMu)