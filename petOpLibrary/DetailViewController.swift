//
//  DetailViewController.swift
//  petOpLibrary
//
//  Created by mac on 4/9/16.
//  Copyright © 2016 Juan Sebastian Castro. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {

    @IBOutlet weak var detailDescriptionLabel: UILabel!
    
    @IBOutlet weak var mostrarTitulo: UILabel!
    @IBOutlet weak var mostrarISBN: UILabel!
    @IBOutlet weak var mostrarAutores: UITextView!
    @IBOutlet weak var mostrarPortada: UIImageView!
    
    var detalleItem : Libro? {
        didSet {
            // Update the view.
            self.configureView()
        }
    }

    func configureView() {
        // Update the user interface for the detail item.
        /*if let detail = self.detailItem {
            if let label = self.detailDescriptionLabel {
                label.text = detail.valueForKey("timeStamp")!.description
            }
        }*/
    
        if let detalle = self.detalleItem {
            if let label = self.mostrarTitulo {
                label.text = detalle.titulo
            }
            if let isbnLabel = self.mostrarISBN {
                isbnLabel.text = detalle.isbn
            }
            
            if let portada = self.mostrarPortada{
                portada.image = detalle.portada
            }
            if let autores = self.mostrarAutores{
                var listaAutores: String = "Authors:\n"
                for autor in detalle.autores{
                    listaAutores = listaAutores+"\(autor)\n"
                }
                autores.text = listaAutores as String
            }
            
        }
    
    
    
    
    
    
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.configureView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

