package com.citt.persistence.services;

import com.citt.exceptions.DespachoNotFoundException;
import com.citt.persistence.entity.Despacho;

import java.util.List;

public interface DespachoService {
    List<Despacho> findAllDespachos();
    Despacho saveDespacho(Despacho despacho);
    Despacho updateDespacho(Long idDespacho, Despacho despacho);
    void deleteDespacho(Long idDespacho);
    Despacho findById(Long idDespacho);
}