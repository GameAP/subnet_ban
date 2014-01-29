<?php if (!defined('BASEPATH')) exit('No direct script access allowed');
/**
 * Game AdminPanel (АдминПанель)
 *
 * 
 *
 * @package		Game AdminPanel
 * @author		Nikita Kuznetsov (ET-NiK)
 * @copyright	Copyright (c) 2014, Nikita Kuznetsov (http://hldm.org)
 * @license		http://www.gameap.ru/license.html
 * @link		http://www.gameap.ru
 * @filesource	
 */
 
/**
 * Структура базы данных модуля "Бан подсетей"
 *
 * @package		Game AdminPanel
 * @category	Controllers
 * @category	Controllers
 * @author		Nikita Kuznetsov (ET-NiK)
 */

$this->load->dbforge();

/*----------------------------------*/
/* 				sb_databases		*/
/*----------------------------------*/
if (!$this->db->table_exists('sb_databases')) {
	$fields = array(
					'id' => array(
						'type' => 'INT',
						'constraint' => 16, 
						'auto_increment' => true
					),
					
					'name' => array(
						'type' 		=> 'TINYTEXT',
					),
					
					'hostname' => array(
						'type' 		=> 'TINYTEXT',
					),
					
					'username' => array(
						'type' => 'TINYTEXT',
					),
					
					'password' => array(
						'type' => 'TEXT',
					),
					
					'database' => array(
						'type' => 'TINYTEXT',
					),
					
					'dbdriver' => array(
						'type' => 'TINYTEXT',
					),
					
					'table_name' => array(
						'type' => 'TINYTEXT',
					),
					
					'dbprefix' => array(
						'type' 			=> 'CHAR',
						'constraint' 	=> 64, 
						'default'		=> '',
					),
					
					'char_set' => array(
						'type' 			=> 'CHAR',
						'constraint' 	=> 64, 
						'default'		=> 'latin1',
					),
					
					'dbcollat' => array(
						'type' 			=> 'CHAR',
						'constraint' 	=> 64, 
						'default'		=> 'latin1_general_ci',
					),
	);
	
	$this->dbforge->add_field($fields);
	$this->dbforge->add_key('id', true);
	$this->dbforge->create_table('sb_databases');
}
